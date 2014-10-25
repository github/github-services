require File.expand_path('../helper', __FILE__)

class KanbanizeTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = '/index.php/api/kanbanize/git_hub_event'
    @stubs.post url do |env|
      assert_equal 'testdomain.kanbanize.com', env[:url].host
      assert_equal '/index.php/api/kanbanize/git_hub_event', env[:url].request_uri
      assert_equal %({"a":1}), env[:body]
      assert_equal 'a1b2c3==', env[:request_headers]['apikey']
      [200, {}, '']
    end

    svc = service({'kanbanize_domain_name' => 'testdomain.kanbanize.com', 'kanbanize_api_key' => 'a1b2c3=='}, 'a' => 1)
    svc.receive_push
  end

  def service(*args)
    super Service::Kanbanize, *args
  end
end
