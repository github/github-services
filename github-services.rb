$:.unshift *Dir["#{File.dirname(__FILE__)}/vendor/**/lib"]
%w( rack sinatra tinder json net/http net/https socket timeout xmlrpc/client openssl basecamp xmpp4r xmpp4r-simple ).each { |f| require f }

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

Dir["#{File.dirname(__FILE__)}/services/**/*.rb"].each { |service| load service }
