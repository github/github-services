require File.expand_path('../helper', __FILE__)

class LeantoTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = "/api/abc/commit"
    @stubs.post url do |env|
      assert_equal "payload=%22payload%22", env[:body]
      [200, {}, '']
    end

    svc = service :push, {'token' => 'abc'}, 'payload'
    svc.receive
  end

  def service(*args)
    super Service::Leanto, *args
  end
end
