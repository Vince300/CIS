require "drb/drb"
require "tmpdir"

# The distributed worker object
class WorkerDispatch
    include DRbUndumped

    attr_reader :logger, :config

    def initialize(logger, config)
        @logger = logger
        @config = config
    end

    def schedule_job(job_file)
        logger.info("schedule_job #{job_file}")

        tmpdir = Dir.mktmpdir
        if system("tar", "-C", tmpdir, "-xf", job_file.path)
            FileUtils.rmdir(tmpdir)
            return "working on #{job_file} in #{tmpdir}"
        else
            failrq("could not read job archive #{job_file}")
        end
    end

    def failrq(msg)
        logger.warn(msg)
        fail msg
    end
end
