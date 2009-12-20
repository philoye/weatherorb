require 'application'

if ENV['RACK_ENV'] != 'production'
  log = File.new("log/sinatra.log", "w")
  STDOUT.reopen(log)
  STDERR.reopen(log)
end

run WeatherOrb::Application
