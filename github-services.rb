$:.unshift *Dir["#{File.dirname(__FILE__)}/vendor/**/lib"]
%w( rack sinatra tinder twitter json net/http socket timeout ).each { |f| require f }

module GitHub
  def service(name, &block)
    post "/#{name}/" do
      data = JSON.parse(params[:data])
      payload = JSON.parse(params[:payload])
      yield data, payload
    end
  end
end
include GitHub

Dir['services/**/*.rb'].each { |service| load service }
