require 'sinatra'
require 'rest_client'
require 'date'
require 'fileutils'
require 'yaml'
require_relative '../helpers.rb'

config = YAML.load_file(File.expand_path('../../config.yml', __FILE__))
sites_table = config['sites_table']

site_cert = OpenSSL::X509::Certificate.new(File.read(config['site']['cert']))
site_key = OpenSSL::PKey::RSA.new(File.read(config['site']['key']))
ca_others_file = config['others']['ca']

# Receive response from worker
post '/result/:id' do |id|
    # Verify the result file
    tempfile = check_file_param(params, 'result', config['max_file_size'])

    site_id, username, job_id = id.split(':')

    if site_id == config['us']
        dirname = "job_" + DateTime.now.strftime("%e_%-m_%y__%k_%M_%S") 
        filename = "/home/"+username+"/"+dirname+"temp.tar.gz"

        FileUtils.cp(tempfile.path, filename)
        FileUtils.chmod(0666, filename)

        cmd = "echo 'The job number #{job_id} is done, result has been stored in #{filename}' | mail -s 'job #{job_id} done' #{username}@localhost"
        system(cmd)
        
        halt 200
    else
        puts "got result for #{id}"
        site_url = sites_table[site_id]
        begin
            RestClient::Resource.new(
                "#{site_url}/result/#{job_id}",
                :ssl_client_cert  =>  site_cert,
                :ssl_client_key   =>  site_key,
                :ssl_ca_file      =>  ca_others_file,
                :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
            ).post(
                :result => tempfile,
                :user => username
            )
        rescue RestClient::Exception => e
            puts e
            halt 503, e.response
        rescue StandardError => e
            puts e
            halt 503, "could not post job result to remote site"
        end
    end
end
