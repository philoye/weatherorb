require 'sinatra' 
require 'haml'
require 'smoke'
require 'parsedate'

module WeatherOrb
  class Application < Sinatra::Base

    set :public, File.join(File.dirname(__FILE__),'public')
    set :views, File.join(File.dirname(__FILE__),'views')
    set :static, true

    helpers do
      def versioned_stylesheet(stylesheet)
        "/#{stylesheet}.css?" + File.mtime(File.join(File.dirname(__FILE__), "public", "#{stylesheet}.css")).to_i.to_s
      end
      def versioned_javascript(js)
        "/#{js}.js?" + File.mtime(File.join(File.dirname(__FILE__), "public", "#{js}.js")).to_i.to_s
      end
      def day_from_date(datestring)
        Date.parse(datestring).strftime("%A")
      end
    end

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