require File.expand_path('../helper', __FILE__)

class FriendFeedTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service({'nickname' => 'n', 'remotekey' => 'r'}, payload)

    @stubs.post "/api/share" do |env|
      assert_equal basic_auth(:n, :r), env[:request_headers][:authorization]
      [200, {}, '']
    end

    svc.receive_push
  end

  def service(*args)
    super Service::FriendFeed, *args
  end
end




