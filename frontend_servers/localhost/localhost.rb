require 'sinatra'
require 'rest_client'
require 'date'
require 'fileutils'
require_relative '../helpers.rb'

config = YAML.load_file(File.expand_path('../../config.yml', __FILE__))

daily_quota = {}
last_date = nil

client_cert = OpenSSL::X509::Certificate.new(File.read(config['localhost']['cert']))
client_key = OpenSSL::PKey::RSA.new(File.read(config['localhost']['key']))
ca_machines_file = config['localhost']['ca']

site_cert = OpenSSL::X509::Certificate.new(File.read(config['site']['cert']))
site_key = OpenSSL::PKey::RSA.new(File.read(config['site']['key']))
ca_others_file = config['others']['ca']

# Receive a job request
post '/job/:id' do |id|
    # Get the username from its CA
    username = /^.*\/CN=(.*)$/.match(request.env['HTTP_X_SSL_CLIENT_S_DN'])[1]

    # Abort on invalid input file
    job_file = check_file_param(params, 'job', config['max_file_size'])

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

    if daily_quota[:username] > config['max_daily_jobs']
        halt 429, "Trop de requêtes journalières"
    end

    externalize_host = params['externalize']
    externalize_host = nil if not externalize_host.nil? and externalize_host.empty?

    if externalize_host and not config['distant_sites'].include? externalize_host
        halt 403, "Hôte externe non autorisé"
    end

    target = nil
    unless externalize_host
        target = config['local_workers'].shuffle.find do |worker_url|
            begin
                RestClient::Resource.new(
                    worker_url + "/stat/running_jobs",
                    :ssl_client_cert  =>  client_cert,
                    :ssl_client_key   =>  client_key,
                    :ssl_ca_file      =>  ca_machines_file,
                    :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
                ).get.body.to_i < config['worker_load_limit']
            rescue StandardError => e
                puts e.message
                false
            end
        end
    end

    if target
        id_to_send = "cis2:" + username + ":" + id.to_s 
        begin
            RestClient::Resource.new(
                target + "/job/"+id_to_send,
                :ssl_client_cert  =>  client_cert,
                :ssl_client_key   =>  client_key,
                :ssl_ca_file      =>  ca_machines_file,
                :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
            ).post(:job => job_file)
        rescue RestClient::Exception => e
            puts e.message
            halt 503, e.response
        rescue StandardError => e
            puts e.message
            halt 503, "Impossible de contacter le worker choisi"
        end
    else 
        site_url = externalize_host || config['distant_sites'].sample

        begin
            RestClient::Resource.new(
                site_url + "/job/"+id,
                :ssl_client_cert  =>  site_cert,
                :ssl_client_key   =>  site_key,
                :ssl_ca_file      =>  ca_others_file,
                :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
            ).post(:job => job_file, :username => username)
        rescue RestClient::Exception => e
            puts e.message
            halt 503, e.response
        rescue StandardError => e
            puts e.message
            halt 503, "Impossible de contacter le site distant #{site_url}"
        end
    end
end
