require 'sinatra'
require 'rest_client'
require 'date'

LOCAL_WORKERS = ["http://ensipc389:80"]


# Receive a job request
post '/job/:id' do |id|
	id_worker = rand LOCAL_WORKERS.length
	worker_url = LOCAL_WORKERS[id_worker]
	begin
		RestClient.post(worker_url + "/job/"+id.to_s,
		:job => params['job'][:tempfile])
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
