require 'logger'
require 'drb/drb'
require 'yaml'
require 'daemons'
require_relative 'worker_dispatch'

# Start dRuby and wait for exit
config = YAML.load_file(ARGV[0] || File.expand_path('../config.yml', __FILE__))
logger = Logger.new(STDOUT)
wd = WorkerDispatch.new(logger, config)

DRb.start_service(config['service_url'], wd)
logger.info("cis workerd running on #{DRb.uri}")

Daemons.daemonize if ARGV.include? '-d'

DRb.thread.join
