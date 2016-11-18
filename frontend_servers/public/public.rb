require 'sinatra'
require 'rest_client'
require 'date'
require 'fileutils'
require 'yaml'

LOCAL_WORKERS = ["https://ensipc375", "https://ensipc377"]

MAX_FILE_SIZE = 10485760

ip_table = YAML.load_file(File.expand_path('./ip-table.yml', __FILE__))

# Receive a job request
post '/job/:id' do |id|


	# Abort on missing input file
	unless params.include? 'job' and params['job'].include? :tempfile 
		status 400
		break
	end

	job_file = params['job'][:tempfile]

	if job_file.size > MAX_FILE_SIZE
		halt 413
	end

	cn = (request.env['HTTP_X_SSL_CLIENT_S_DN'].split('/').map { |dn_part| dn_part.split('=') }.find { |dn_part| dn_part[0] == 'CN' })[1]

	username = params['user'] || params['username']

	id_to_send = ip_table[cn] + ':' + username + ':' id.to_s

	id_worker = rand LOCAL_WORKERS.length
	
	


	worker_url = LOCAL_WORKERS[id_worker]
	begin
		RestClient::Resource.new(
			worker_url + "/job/"+id_to_send,
			:ssl_client_cert  =>  OpenSSL::X509::Certificate.new(File.read("/srv/machine.crt")),
			:ssl_client_key   =>  OpenSSL::PKey::RSA.new(File.read("/srv/machine.key"), ""),
			:ssl_ca_file      =>  "/srv/machines.pem",
			:verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
			).post(:job => job_file)
	rescue RestClient::Exception => e
		puts e
		status 503
		body e.response
	end
end