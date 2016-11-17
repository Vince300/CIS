require 'sinatra'
require 'rest_client'
require 'date'
require 'fileutils'

# Receive response from worker
post '/result/:id' do |id|
	username = id.split(':')[1]
	
	tempfile = params['result'][:tempfile]
	dirname = "job_" + DateTime.now.strftime("%e_%-m_%y__%k_%M_%S") 
	filename = "/home/"+username+"/"+dirname+"temp.tar.gz"
	FileUtils.cp(tempfile.path, filename)
	FileUtils.chmod(0666, filename)
	status 200
end
