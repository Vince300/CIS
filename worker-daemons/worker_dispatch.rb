require "drb/drb"
require "tmpdir"
require "open3"
require "time"
require "restclient"

# The distributed worker object
class WorkerDispatch
    include DRbUndumped

    attr_reader :logger, :config

    def initialize(logger, config)
        @logger = logger
        @config = config
        @managed_containers = {}
        @pending_die_events = []
        @mtx = Mutex.new

        # Start with a clean environment
        docker_start_cleanup

        # Start listening for container events
        docker_listen_events
    end

    def schedule_job(job_file, job_id, job_local = nil)
        logger.info("schedule_job #{job_file} #{job_id}")

        tmpdir = Dir.mktmpdir(config['tmp_prefix'])

        # Prepare the jobid File
        File.open(File.join(tmpdir, 'jobid'), 'w') do |f|
            f.puts job_id
        end 

        # The actual job directory
        job_dir = File.join(tmpdir, 'job')
        Dir.mkdir(job_dir)

        if system("tar", "-C", job_dir, "-xf", File.expand_path(job_file.to_s))
            begin
                # Start the container
                container_id = docker_run(job_dir, job_id, job_local)
                logger.info("successfully started job #{job_id} in #{job_dir} using #{container_id}")

                return "working on #{job_id}"
            rescue StandardError => e
                FileUtils.rmdir(tmpdir)
                failrq(e)
            end
        else
            FileUtils.rmdir(tmpdir)
            failrq("could not read job archive #{job_file}")
        end
    end

    private
    def failrq(msg)
        logger.warn(msg)
        fail msg
    end

    def docker_start_cleanup
        logger.info("docker_start_cleanup")

        system("docker stop $(docker ps -a -q) >/dev/null 2>&1")
        system("docker rm $(docker ps -a -q) >/dev/null 2>&1")

        Dir.glob(File.join(Dir.tmpdir, config['tmp_prefix'] + '*')).each do |dir|
            begin
                logger.info("removing #{dir}")
                FileUtils.rmtree(dir)
            rescue
            end
        end
    end

    def docker_listen_events
        Thread.start do
            Open3.popen3("docker", "events", "--filter", "type=container") do |stdin, stdout, stderr, wait_thr|
                loop do
                    date_time, event_type, event, id, details = stdout.gets.split

                    if event == 'die'
                        job = @mtx.synchronize {
                            j = @managed_containers[id]
                            @pending_die_events << id unless j
                            j
                        }

                        if job
                            on_container_die(job)
                        else
                            logger.info("pending #{event} event for #{id}")
                        end
                    end
                end
            end
        end
    end

    def reprocess_events
        our_events = @pending_die_events.dup
        Thread.start do
            our_events.each do |id|
                logger.info("trying to reprocess #{id}")
                if job = @managed_containers[id]
                    logger.info("handling die event for #{id}")
                    @pending_die_events.delete(id)
                    on_container_die(job)
                end
            end
        end
    end

    def with_running_container(container_id)
        begin
            fail "could not restart container" unless system("docker", "start", container_id)
            yield
        ensure
            system("docker", "stop", container_id)
        end
    end

    def on_container_die(job_spec)
        container_id = job_spec[:container_id]
        @managed_containers.delete container_id

        job_id = job_spec[:job_id]
        job_dir = job_spec[:job_dir]
        tmp_dir = File.expand_path('..', job_dir)

        result_archive_path = File.join(tmp_dir, 'result.tar.gz')
        result_job_log = File.join(tmp_dir, 'job.log')
        result_output_log = File.join(tmp_dir, 'output.log') 

        begin

            logger.info("container for #{job_id} terminated")

            # Pull result files
            docker_cp(container_id, job_spec[:job_log], result_job_log)
            docker_cp(container_id, job_spec[:output_log], result_output_log)

            # Tar the files
            logger.info("preparing the result archive")
            
            unless system("tar", "-C", tmp_dir, "-czf", result_archive_path, "job.log", "output.log")
                # failed to prepare the archive, this is fatal
                fail "could not prepare result archive"
            end

            # ensure limit on archive size
            if (sz = File.size(result_archive_path)) > config['max_result_size']
                # change job.log
                File.open(result_job_log, "a") do |jl|
                    jl.puts "resulting archive was #{sz} bytes, too big"
                end

                # retar, job logs only
                FileUtils.rm(result_archive_path)
                unless system("tar", "-C", tmp_dir, "-czf", result_archive_path, "job.log", "output.log")
                    fail "could not prepare result archive"
                end
            end

            logger.info("resulting archive #{result_archive_path} for #{job_id} is #{File.size(result_archive_path)} bytes")

            if job_spec[:job_local]
                logger.info("local job result sent to #{job_spec[:job_local]}")
                FileUtils.mv(result_archive_path, job_spec[:job_local])
            else
                fail "not yet implemented"
            end
        rescue StandardError => e
            logger.error(e)
        ensure
            # ensure cleanup
            logger.info("cleaning #{tmp_dir}")
            FileUtils.rmtree(tmp_dir)
        end
    end

    def randstring
        "cis" + rand(36**8).to_s(36)
    end

    def docker_cp(container_id, src, dst)
        logger.info("cp #{container_id}:#{src} #{dst}")
        system("docker", "cp", "#{container_id}:#{src}", dst)
    end

    def docker_run(job_dir, job_id, job_local = nil)
        logger.info("docker_run #{job_dir} #{job_id}")

        # Build the docker command line
        command = [
            "docker",
            "run",
            "--network", # No network
            "none",
        ]

        # Add limits
        config['limits'].each do |key, value|
            command << "--#{key}"
            command << value.to_s
        end

        # Mount the temp directory as /mnt/job
        command << "-v"
        command << "#{job_dir}:/mnt/job:ro"

        # Daemonize
        command << "-d"

        # Add docker image
        command << config['docker_image']

        # Randomize output files
        job_log = File.join("/mnt", randstring)
        output_log = File.join("/mnt", randstring)

        # The command to run
        command << "/bin/bash"
        command << "-c"
        command << "cd && cp -r /mnt/job . && cd job && chmod +x ./job && ./job >#{output_log} 2>&1 ; echo \"job exited with status $?\" >#{job_log}"

        # Get the container id
        container_id, stderr_str, status = Open3.capture3(*command)

        logger.debug(command.inspect)

        if status.success?
            container_id.strip!

            @mtx.synchronize do
                # Store data for later
                @managed_containers[container_id] = {
                    job_dir: job_dir,
                    job_id: job_id,
                    container_id: container_id,
                    job_log: job_log,
                    output_log: output_log,
                    started_at: DateTime.now,
                    job_local: job_local
                }
                reprocess_events
            end

            return container_id
        else
            fail "failed to start job: #{stderr_str}"
        end
    end

end
