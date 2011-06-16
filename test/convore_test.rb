require File.expand_path('../helper', __FILE__)

class ConvoreTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = "/api/topics/1/messages/create.json"
    @stubs.post url do |env|
      assert_equal 'application/x-www-form-urlencoded', env[:request_headers]["Content-Type"]
      assert_equal basic_auth(:rick, :monkey), env[:request_headers]['authorization']
      assert_match /grit/, env[:body]
      [200, {}, '']
    end

    svc = service({
      'topic_id' => '1',
      'username' => 'rick',
      'password' => 'monkey'
    }, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Convore, *args
  end
end

