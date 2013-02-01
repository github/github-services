require File.expand_path('../helper', __FILE__)

class GithubPendingStatusTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.get url do |env|
      assert_equal basic_auth(:u, :p), env[:request_headers]['authorization']
      [200, {}, '']
    end

    svc = service({
      'username' => 'u',
      'password' => 'p'
    }, 'payload')
    svc.receive_push
  end

  def service(*args)
    super Service::TeamCity, *args
  end
end

