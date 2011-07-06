require File.expand_path('../helper', __FILE__)

class CoOpTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service({'group_id' => 'abc', 'token' => 'def'}, payload)

    num = 0
    @stubs.post "/groups/abc/notes" do |env|
      data = JSON.parse env[:body]
      assert_match /tom/i, data['status']
      assert_equal 'def', data['key']

      assert_equal 'GitHub Notifier', env[:request_headers]['User-Agent']
      assert_equal 'application/json; charset=utf-8',
        env[:request_headers]['Content-Type']
      assert_equal 'application/json',
        env[:request_headers]['Accept']

      num += 1

      [200, {}, '']
    end

    svc.receive_push
    assert_equal 3, num

    @stubs.verify_stubbed_calls
  end

  def service(*args)
    super Service::CoOp, *args
  end
end



