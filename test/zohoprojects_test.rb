require File.expand_path('../helper', __FILE__)

class ZohoProjectsTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def data
    {
      "project_id" => "1234",
      "token" => "a13d",
    }
  end

  def test_push
    url = "/serviceHook"
    @stubs.post url do |env|
	    assert_match /(^|\&)pId=1234($|\&)/, env[:body]
	    assert_match /(^|\&)authtoken=a13d($|\&)/, env[:body]
      [200, {}, '']
    end
	
    svc = service :push, data , payload
    svc.receive
  end

  def service(*args)
    super Service::ZohoProjects, *args
  end
end

