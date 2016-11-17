require 'sinatra'
require 'rest_client'
require 'date'

LOCAL_WORKERS = ["https://ensipc389:80"]


# Receive a job request
post '/job/:id' do |id|
	# Abort on missing input file
	unless params.include? 'job' and params['job'].include? :tempfile 
		status 400
		break
	end

	id_worker = rand LOCAL_WORKERS.length
	 
	 
	 worker_url = LOCAL_WORKERS[id_worker]
	 begin
		RestClient::Resource.new(
			worker_url + "/job/"+id.to_s,
			:ssl_client_cert  =>  OpenSSL::X509::Certificate.new(File.read("/etc/nginx/cert/server_test.crt")),
			:ssl_client_key   =>  OpenSSL::PKey::RSA.new(File.read("/etc/nginx/cert/server_test.key"), "0000"),
			:ssl_ca_file      =>  "/etc/nginx/cert/ca_test.crt",
			:verify_ssl       =>  OpenSSL::SSL::VERIFY_NONE
		).post(:job => params['job'][:tempfile])
	 rescue RestClient::Exception => e
	 	status 415
	 	body e.response
	 end
end

# Receive response from worker
post '/result/:id' do |id|
	username = "admin"
	
	tempfile = params['jobresult'][:tempfile]
	dirname = "Job " + DateTime.strftime("%e_%-m_%y__%k:%M:%S") 

	File.copy(tempfile.path, "/home/"+username+"/"+dirname+"temp.tar.gz")
	status 200
end
