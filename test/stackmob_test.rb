require File.expand_path('../helper', __FILE__)

class StackmobTest < Service::TestCase

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push_valid
    token = "abcdefg"
    @stubs.post "/callback/#{token}" do |env|
      assert_equal payload.to_json, env[:body]
      [200, {}, '']
    end

    svc = service :push, { Service::Stackmob::TOKEN_KEY => token }, payload
    svc.receive_push
    @stubs.verify_stubbed_calls
  end

  def test_push_missing_token
    svc = service :push, { Service::Stackmob::TOKEN_KEY => '' }, payload
    assert_raises Service::ConfigurationError do 
      svc.receive_push
    end
  end

  def service(*args)
    super Service::Stackmob, *args
  end

end
