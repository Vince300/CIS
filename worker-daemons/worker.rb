require 'sinatra'
require 'tmpdir'

set :bind, '0.0.0.0'
set :port, 80

post '/job/:id' do |id|
    # Abort on missing input file
    unless params.include? 'job' and params['job'].include? :tempfile 
        status 400
        break
    end

    puts params['job'].inspect
    job_file = params['job'][:tempfile]
    
    tmpdir = Dir.mktmpdir
    if system("tar", "-C", tmpdir, "-xf", job_file.path)
        # LOL ON LANCE DOCKER

        # success
        status 200 
        body ''
    else
        status 415
        body "could not read job archive\n"
    end
end
