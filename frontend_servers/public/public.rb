require 'sinatra'
require 'rest_client'
require 'date'
require 'fileutils'
require 'yaml'
require 'uri'
require_relative '../helpers.rb'

config = YAML.load_file(File.expand_path('../../config.yml', __FILE__))
sites_table = config['sites_table']
ip_table = sites_table.map { |key, val| [URI.parse(val).host, key] }.to_h

daily_quota = {}
last_date = nil

client_cert = OpenSSL::X509::Certificate.new(File.read(config['machine']['cert']))
client_key = OpenSSL::PKey::RSA.new(File.read(config['machine']['key']))
ca_machines_file = config['machine']['ca']

# Receive a job request
post '/job/:id' do |id|
    puts "/job/#{id}"

    # Abort on invalid input file
    job_file = check_file_param(params, 'job', config['max_file_size'])

    # Check for username
    username = params['user'] || params['username']

    unless username
        halt 400
    end

    # Find CN in ip_table
    cn = (request.env['HTTP_X_SSL_CLIENT_S_DN'].split('/').map { |dn_part| dn_part.split('=') }.find { |dn_part| dn_part[0] == 'CN' })[1]
    
    # Deny requests for unknown
    unless ip_table[cn]
        puts "denied CN #{cn} because it was not in the ip_table: #{ip_table.inspect}"
        halt 403
    end

    id_to_send = "#{ip_table[cn]}:#{username}:#{id}"
    
    time = Time.new
    if last_date != time.day
        last_date = time.day
        daily_quota = Hash.new()
    end
    if daily_quota[cn].nil?
        daily_quota[cn] = 1
    else
        daily_quota[cn] += 1
    end

    if daily_quota[cn] > config['max_daily_jobs']
        puts "site #{cn} exceeded its daily quota"
        halt 429, "Too many daily requests"
    end

    worker_url = config['local_workers'].sample
    begin
        RestClient::Resource.new(
            worker_url + "/job/"+id_to_send,
            :ssl_client_cert  =>  client_cert,
            :ssl_client_key   =>  client_key,
            :ssl_ca_file      =>  ca_machines_file,
            :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
            ).post(:job => job_file)
        puts "sent job #{id_to_send} to worker #{worker_url}"
    rescue RestClient::Exception => e
        puts e
        halt 503, e.response
    rescue StandardError => e
        halt 500
    end
end

# Receive response from distant entity
post '/result/:id' do |id|
    # Abort on invalid input file
    result_file = check_file_param(params, 'result', config['max_file_size'])

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

    puts "delivered the result of job #{id}"
    status 200
end
