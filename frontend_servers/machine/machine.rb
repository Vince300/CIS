require 'sinatra'
require 'rest_client'
require 'date'
require 'fileutils'
require 'yaml'

sites_table = YAML.load_file(File.expand_path('../sites-table.yml', __FILE__))

site_cert = OpenSSL::X509::Certificate.new(File.read("/srv/cis2.crt"))
site_key = OpenSSL::PKey::RSA.new(File.read("/srv/cis2.key"))
ca_others_file = "/srv/cisothersca.pem"

# Receive response from worker
post '/result/:id' do |id|

	id_split = id.split(':')

	if id_split[0] == 'cis2'

		username = id_split[1]
		
		tempfile = params['result'][:tempfile]
		dirname = "job_" + DateTime.now.strftime("%e_%-m_%y__%k_%M_%S") 
		filename = "/home/"+username+"/"+dirname+"temp.tar.gz"
		FileUtils.cp(tempfile.path, filename)
		FileUtils.chmod(0666, filename)

		cmd = "echo 'The job number #{id_split[2]} is done, result has been stored in #{filename}' | mail -s 'job #{id_split[2]} done' #{username}@localhost"
		system(cmd)
		status 200
	else

		site_url = sites_table[id_split[0]]
		begin
			RestClient::Resource.new(
				site_url + "/result/"+id_split[2],
				:ssl_client_cert  =>  site_cert,
				:ssl_client_key   =>  site_key,
				:ssl_ca_file      =>  ca_others_file,
				:verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
				).post(:result => params['result'][:tempfile])
		rescue RestClient::Exception => e
			puts e
			status 503
			body e.response
		end
	end
end
