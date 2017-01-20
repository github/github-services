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
      assert_equal %({"ref":"refs/heads/master"}), env[:body]
      assert_equal 'a1b2c3==', env[:request_headers]['apikey']
      assert_equal '', env[:request_headers]['branch-filter']
      assert_equal false, env[:request_headers]['last-commit']
      assert_equal false, env[:request_headers]['track-issues']
      assert_equal '', env[:request_headers]['board-id']
      [200, {}, '']
    end

    svc = service({'kanbanize_domain_name' => 'testdomain.kanbanize.com', 'kanbanize_api_key' => 'a1b2c3=='}, {'ref' => 'refs/heads/master'})
    svc.receive_event
  end

  def test_push_with_restrictions
    url = '/index.php/api/kanbanize/git_hub_event'
    @stubs.post url do |env|
      assert_equal 'testdomain.kanbanize.com', env[:url].host
      assert_equal '/index.php/api/kanbanize/git_hub_event', env[:url].request_uri
      assert_equal %({"ref":"refs/heads/mybranch2"}), env[:body]
      assert_equal 'a1b2c3==', env[:request_headers]['apikey']
      assert_equal 'mybranch1,mybranch2', env[:request_headers]['branch-filter']
      assert_equal true, env[:request_headers]['last-commit']
      assert_equal false, env[:request_headers]['track-issues']
      assert_equal '', env[:request_headers]['board-id']
      [200, {}, '']
    end

    svc = service({'kanbanize_domain_name' => 'testdomain.kanbanize.com', 'kanbanize_api_key' => 'a1b2c3==', 'restrict_to_branch' => 'mybranch1,mybranch2', 'restrict_to_last_commit' => '1'}, {'ref' => 'refs/heads/mybranch2'})
    svc.receive_event
  end

  def test_push_with_issue_tracking
    url = '/index.php/api/kanbanize/git_hub_event'
    @stubs.post url do |env|
      assert_equal 'testdomain.kanbanize.com', env[:url].host
      assert_equal '/index.php/api/kanbanize/git_hub_event', env[:url].request_uri
      assert_equal %({"action":"created"}), env[:body]
      assert_equal 'a1b2c3==', env[:request_headers]['apikey']
      assert_equal '', env[:request_headers]['branch-filter']
      assert_equal false, env[:request_headers]['last-commit']
      assert_equal true, env[:request_headers]['track-issues']
      assert_equal '131', env[:request_headers]['board-id']
      [200, {}, '']
    end
	
    svc = service(:issues, {'kanbanize_domain_name' => 'testdomain.kanbanize.com', 'kanbanize_api_key' => 'a1b2c3==', 'track_project_issues_in_kanbanize' => '1', 'project_issues_board_id' => '131'}, {'action' => 'created'})
    svc.receive_event
  end

  def service(*args)
    super Service::Kanbanize, *args
  end
end
