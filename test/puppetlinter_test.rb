require File.expand_path('../helper', __FILE__)

class PuppetLinterTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = '/api/v1/hook'
    @stubs.post url do |env|
      assert_equal 'www.puppetlinter.com', env[:url].host
      assert_equal 'application/x-www-form-urlencoded', env[:request_headers]['Content-Type']
      [200, {}, '']
    end

    svc = service(:push, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::PuppetLinter, *args
  end
end
