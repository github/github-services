require File.expand_path('../helper', __FILE__)

class NetlifyTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service :push, {'url' => 'https://api.netlify.com/hooks/github'}, 'a' => 1

    @stubs.post "/hooks/github" do |env|
      assert_equal %({"a":1}), env[:body]
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      [204, {}, '']
    end

    svc.receive

    @stubs.verify_stubbed_calls
  end

  def service(*args)
    super Service::Netlify, *args
  end
end
