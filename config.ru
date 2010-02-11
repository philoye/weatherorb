require 'application'

if ENV['RACK_ENV'] != 'production'
  log = File.new("log/sinatra.log", "w")
  $stdout.reopen(log)
  $stderr.reopen(log)
end

run WeatherOrb::Application
