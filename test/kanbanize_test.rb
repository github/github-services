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
      assert_equal nil, env[:request_headers]['restrict_to_branch']
      assert_equal nil, env[:request_headers]['restrict_to_last_commit']
      [200, {}, '']
    end

    svc = service({'kanbanize_domain_name' => 'testdomain.kanbanize.com', 'kanbanize_api_key' => 'a1b2c3=='}, 'a' => 1)
    svc.receive_push
  end

  def test_push_with_restrictions
    url = '/index.php/api/kanbanize/git_hub_event'
    @stubs.post url do |env|
      assert_equal 'testdomain.kanbanize.com', env[:url].host
      assert_equal '/index.php/api/kanbanize/git_hub_event', env[:url].request_uri
      assert_equal %({"a":1}), env[:body]
      assert_equal 'a1b2c3==', env[:request_headers]['apikey']
      assert_equal 'mybranch1,mybranch2', env[:request_headers]['branch-filter']
      assert_equal true, env[:request_headers]['last-commit']
      [200, {}, '']
    end

    svc = service({'kanbanize_domain_name' => 'testdomain.kanbanize.com', 'kanbanize_api_key' => 'a1b2c3==', 'restrict_to_branch' => 'mybranch1,mybranch2', 'restrict_to_last_commit' => '1'}, 'a' => 1)
    svc.receive_push
  end


  def service(*args)
    super Service::Kanbanize, *args
  end
end
