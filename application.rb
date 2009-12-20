require 'sinatra' 
require 'haml'
require 'smoke'

module WeatherOrb
  class Application < Sinatra::Base

    Smoke.configure do |c|
      c[:cache][:enabled] = true
      c[:cache][:store] = :memory
      c[:cache][:expire_in] = 300
    end 
    Smoke.yql(:yahoo_weather) do
      select :all
      from 'weather.forecast'
      where :location, "ASXX0112" # sydney
      where :u, "c"
      path :query, :results, :channel, :item
    end

    before do
      @weather = Smoke[:yahoo_weather].output.first
    end
    
    get '/' do
      haml :index, { :format => :html5 }
    end

    get '/weather.xml' do
      content_type 'text/xml', :charset => 'utf-8'
      haml :api, { :format => :xhtml }
    end      
      
  end
end