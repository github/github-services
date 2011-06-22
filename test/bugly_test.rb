require File.expand_path('../helper', __FILE__)

class BuglyTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service :push, {'token' => 'abc'}, 'a' => 1

    @stubs.post "/changesets.json" do |env|
      assert_equal %({"a":1}), env[:body]
      assert_equal 'abc', env[:request_headers]['X-BuglyToken']
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      [200, {}, '']
    end

    svc.receive

    @stubs.verify_stubbed_calls
  end

  def service(*args)
    super Service::Bugly, *args
  end
end



