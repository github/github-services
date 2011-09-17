require File.expand_path('../helper', __FILE__)

class SourcemintTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = "/actions/post-commit"
    @stubs.post url do |env|
      assert_equal 'api.sourcemint.com', env[:url].host
      assert_equal "payload=%22payload%22", env[:body]
      [200, {}, '']
    end

    svc = service :push, {}, 'payload'
    svc.receive
  end

  def service(*args)
    super Service::Sourcemint, *args
  end
end

