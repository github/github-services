require File.expand_path('../helper', __FILE__)

class StatusNetTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/api/statuses/update.xml" do |env|
      assert_equal 's.com', env[:url].host
      data = Faraday::Utils.parse_nested_query(env[:body])
      assert_equal 'github', data['source']
      [200, {}, '']
    end

    svc = service({'server' => 'http://s.com'}, payload)

    def svc.shorten_url(*args)
      'short'
    end

    svc.receive_push
  end

  def service(*args)
    super Service::StatusNet, *args
  end
end

