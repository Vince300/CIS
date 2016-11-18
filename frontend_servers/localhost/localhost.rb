require 'sinatra'
require 'rest_client'
require 'date'
require 'fileutils'

LOCAL_WORKERS = ["https://ensipc375", "https://ensipc377"]

LOCAL_WORKERS = ["https://ensipc375", "https://ensipc377"]

MAX_FILE_SIZE = 10485760

MAX_DAILY_JOBS = 500
daily_quota = {}
last_date = nil

client_cert = OpenSSL::X509::Certificate.new(File.read("/srv/machine.crt"))
client_key = OpenSSL::PKey::RSA.new(File.read("/srv/machine.key"))
ca_machines_file = "/srv/machines.pem"

site_cert = OpenSSL::X509::Certificate.new(File.read("/srv/cis2.crt"))
site_key = OpenSSL::PKey::RSA.new(File.read("/srv/cis2.key"))
ca_others_file = "/srv/cisothersca.pem"

# Receive a job request
post '/job/:id' do |id|

	username = /^.*\/CN=(.*)$/.match(request.env['HTTP_X_SSL_CLIENT_S_DN'])[1]

	# Abort on missing input file
	unless params.include? 'job' and params['job'].include? :tempfile 
		status 400
		break
	end

    job_file = params['job'][:tempfile]

    if job_file.size > MAX_FILE_SIZE
        halt 413
    end

	id_to_send = "cis2:" + id.to_s

	id_worker = rand LOCAL_WORKERS.length
	 
	 
	worker_url = LOCAL_WORKERS[id_worker]

	time = Time.new
	if last_date != time.day
		last_date = time.day
		daily_quota = Hash.new()
	end
	if daily_quota[:username] == nil
		daily_quota[:username] = 1
	else
		daily_quota[:username] += 1
	end

	if daily_quota[:username] > MAX_DAILY_JOBS
		halt 429, "Trop de requêtes journalières"
	end

	begin
		RestClient::Resource.new(
			worker_url + "/job/"+id_to_send,
			:ssl_client_cert  =>  client_cert,
			:ssl_client_key   =>  client_key,
			:ssl_ca_file      =>  ca_machines_file,
			:verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
		).post(:job => job_file)
	rescue RestClient::Exception => e
		puts e
		status 503
		body e.response
	end
end
