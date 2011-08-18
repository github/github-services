require File.expand_path('../helper', __FILE__)

class HarvestTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.get "/daily" do |env|
      assert_equal 'sub.harvestapp.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      assert_equal 'application/xml', env[:request_headers]["Content-Type"]
      assert_equal 'application/xml', env[:request_headers]["Accept"]
      assert_equal basic_auth(:rick, :monkey), env[:request_headers]['authorization']
      [200, {}, %(
<daily>
  <day_entries>
    <day_entry>
      <id>timer</id>
      <timer_started_at />
      <notes>notes</notes>
      <hours>1</hours>
    </day_entry>
  </day_entries>
</daily>
      )]
    end

    @stubs.post "/daily/update/timer" do |env|
      assert_equal 'sub.harvestapp.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      assert_equal 'application/xml', env[:request_headers]["Content-Type"]
      assert_equal 'application/xml', env[:request_headers]["Accept"]
      assert_equal basic_auth(:rick, :monkey), env[:request_headers]['authorization']
      assert_match /grit/, env[:body]
      assert_match /hours>1<\/hours/, env[:body]
      [200, {}, '{}']
    end

    svc = service({
      'subdomain' => 'sub',
      'username'  => 'rick',
      'ssl'       => 1,
      'password'  => 'monkey'
    }, payload)
    def svc.shorten_url(*args)
      'short'
    end

    svc.receive_push
  end

  def service(*args)
    super Service::Harvest, *args
  end
end


