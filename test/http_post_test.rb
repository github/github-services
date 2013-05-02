require File.expand_path('../helper', __FILE__)

class HttpPostTest < Service::TestCase
  include Service::HttpTestMethods

  def service_class
    Service::HttpPost
  end
end

