require 'sinatra'
require 'tmpdir'
require 'yaml'
require 'drb/drb'
require_relative 'worker_dispatch'

config = YAML.load_file(File.expand_path('../config.yml', __FILE__))

def with_workerd(config)
    attempt = 0
    begin
        # Ensure we have access to the worker object
        unless @workerd
            @workerd = DRbObject.new_with_uri(config['service_url'])
        end
        
        halt 200, yield(@workerd)
    rescue DRb::DRbConnError
        # One more try
        attempt = attempt + 1
        @workerd = nil

        if attempt < config['max_workerd_connect_attempts']
            # we may not have a connection to the agent running in the background
            retry
        else
            # we failed getting a connection to the workerd
            halt 503, "could not connect to the workerd"
        end
    rescue StandardError => e
        logger.error(e)
        # Generic error
        halt 415, e.message
    end
end

get '/stat/:what' do |what|
    with_workerd(config) do |workerd|
        begin
            workerd.get_stat(what.to_s).to_s
        rescue StandardError => e
            logger.error(e)
            halt 404, e.message
        end
    end
end

post '/job/:id' do |id|
    # Abort on missing input file
    unless params.include? 'job' and params['job'].include? :tempfile 
        halt 400
    end

    # Log the CN
    logger.debug(request.env['HTTP_X_SSL_CLIENT_S_DN'])

    # Job file
    job_file = params['job'][:tempfile]

    # Abort if the file size is too important
    if job_file.size > config['max_file_size']
        halt 413
    end

    # Actually schedule the job
    with_workerd(config) do |workerd|
        workerd.schedule_job(job_file.path, id)
    end
end
