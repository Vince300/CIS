require 'sinatra'
require 'rest_client'
require 'date'
require 'fileutils'
require 'yaml'

LOCAL_WORKERS = ["https://ensipc375", "https://ensipc377"]

MAX_FILE_SIZE = 10485760

MAX_DAILY_JOBS = 1000 
daily_quota = {}
last_date = nil

ip_table = YAML.load_file(File.expand_path('../ip-table.yml', __FILE__))


client_cert = OpenSSL::X509::Certificate.new(File.read("/srv/machine.crt"))
client_key = OpenSSL::PKey::RSA.new(File.read("/srv/machine.key"))
ca_machines_file = "/srv/machines.pem"

# Receive a job request
post '/job/:id' do |id|
	# Abort on missing input file
	unless params.include? 'job' and params['job'].include? :tempfile 
		halt 400
	end

	job_file = params['job'][:tempfile]

	if job_file.size > MAX_FILE_SIZE
		halt 413
	end

	# Check for username
	username = params['user'] || params['username']

	unless username
		halt 400
	end

	# Find CN in ip_table
	cn = (request.env['HTTP_X_SSL_CLIENT_S_DN'].split('/').map { |dn_part| dn_part.split('=') }.find { |dn_part| dn_part[0] == 'CN' })[1]
	
	# Deny requests for unknown
	unless ip_table[cn]
		halt 403
	end

	id_to_send = "#{ip_table[cn]}:#{username}:#{id}"
	id_worker = rand LOCAL_WORKERS.length
	
	time = Time.new
	if last_date != time.day
		last_date = time.day
		daily_quota = Hash.new()
	end
	if daily_quota[:cn] == nil
		daily_quota[:cn] = 1
	else
		daily_quota[:cn] += 1
	end

	if daily_quota[:cn] > MAX_DAILY_JOBS
		halt 429, "Too many daily requests"
	end

	worker_url = LOCAL_WORKERS[id_worker]
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
		halt 503, e.response
	rescue StandardError => e
		halt 500
	end
end

# Receive response from distant entity
post '/result/:id' do |id|
	# Abort on missing input file
	unless params.include? 'result' and params['result'].include? :tempfile 
		status 400
		break
	end

	result_file = params['result'][:tempfile]

	if result_file.size > MAX_FILE_SIZE
		halt 413
	end

	# Get username
	username = params['user'] || params['username']

	unless username
		halt 400
	end

	dirname = "job_" + DateTime.now.strftime("%e_%-m_%y__%k_%M_%S") 
	filename = "/home/"+username+"/"+dirname+"temp.tar.gz"
	FileUtils.cp(result_file.path, filename)
	FileUtils.chmod(0666, filename)

	cmd = "echo 'The job number #{id} is done, result has been stored in #{filename}' | mail -s 'job #{id} done' #{username}@localhost"
	system(cmd)
	status 200
end
