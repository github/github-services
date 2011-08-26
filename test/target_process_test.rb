require File.expand_path('../helper', __FILE__)

class TargetProcessTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.get "/api/v1/Context/" do |env|
      assert_equal 'foo.com', env[:url].host
      assert_equal '1', env[:params]['ids']
      [200, {}, '<?xml version="1.0" encoding="utf-16" standalone="yes"?><Context Acid="ZOMG"></Context>']
    end

    @stubs.get "/api/v1/Bugs/" do |env|
      assert_equal 'foo.com', env[:url].host
      assert_equal 'ZOMG', env[:params][:acid]
      [200, {}, '']
    end

    @stubs.post "/Services/ProcessService.asmx" do |env|
      assert_equal 'foo.com', env[:url].host
      [200, {}, '']
    end

    svc = service(
      {'base_url' => 'http://foo.com/', 'username' => 'u', 'password' => 'p',
       'project_id' => '1'},
      payload)
    svc.receive_push
  end

  def service(*args)
    super Service::TargetProcess, *args
  end
end