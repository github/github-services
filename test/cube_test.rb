require File.expand_path('../helper', __FILE__)

class CubeTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = "/integration/events/github/create"
    @stubs.post url do |env|
      assert_match /(^|\&)payload=%7B%22a%22%3A1%7D($|\&)/, env[:body]
      assert_match "project_name=p", env[:body]
      assert_match "project_token=t", env[:body]
      assert_match "domain=d", env[:body]
      [200, {}, '']
    end

    svc = service :push,
      {'project' => 'p', 'token' => 't', 'domain' => 'd'},
      {'a' => 1}
    svc.receive_push
  end

  def service(*args)
    super Service::Cube, *args
  end
end


