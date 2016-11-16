require 'daemons'
Daemons.run(File.expand_path('../workerd.rb', __FILE__))