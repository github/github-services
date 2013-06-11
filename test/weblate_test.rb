require File.expand_path('../helper', __FILE__)

class WeblateTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/hooks/github/" do |env|
      assert_equal 'weblate.example.org', env[:url].host
      assert_equal 'application/x-www-form-urlencoded',
        env[:request_headers]['content-type']
      [200, {}, '']
    end

    svc = service :push,
      {'url' => 'weblate.example.org'}, payload
    svc.receive_push
  end

  def service(*args)
    super Service::Weblate, *args
  end
end
