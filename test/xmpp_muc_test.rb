class XmppMucTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
      
    @config = {
      'JID' => 'me@example.com',
      'password' => 'password',
      'room' => 'status',
      'server' => 'muc.example.com',
      'nickname' => 'github',
      'notify_fork' => true,
      'notify_wiki' => true,
      'notify_comments' => true,
      'notify_watch' => true,
      'notify_issue' => true,
      'notify_deployment' => true,
      'notify_team' => true,
      'notify_pull' => true,
      'notify_release' => true
    }
  end

  def test_no_jid_provided
    assert_raise_with_message(Service::ConfigurationError, 'JID is required') do
      config = @config
      config['JID'] = ''
      service(config, payload).receive_event
    end
  end

  def test_no_password_provided
    assert_raise_with_message(Service::ConfigurationError, 'Password is required') do
      config = @config
      config['password'] = ''
      service(config, payload).receive_event
    end
  end

  def test_no_room_provided
    assert_raise_with_message(Service::ConfigurationError, 'Room is required') do
      config = @config
      config['room'] = ''
      service(config, payload).receive_event
    end
  end

  def test_no_server_provided
    assert_raise_with_message(Service::ConfigurationError, 'Server is required') do
      config = @config
      config['server'] = ''
      service(config, payload).receive_event
    end
  end
    
  def test_returns_false_if_not_on_filtered_branch
    config = @config
    config['filter_branch'] = 'development'
    assert_equal(
      false,
      service(config, payload).receive_event,
      'Should have filtered by branch'
    )  
  end
    
  def test_returns_false_if_fork_event_and_not_notifiying
    config = @config
    config['notify_fork'] = false
    assert_equal(
      false,
      service(:fork, config, payload).receive_event,
      'Should not reported fork event'
    ) 
  end
    
  def test_returns_false_if_watch_event_and_not_notifiying
    config = @config
    config['notify_watch'] = false
    assert_equal(
      false,
      service(:watch, config, payload).receive_event,
      'Should not reported watch event'
    ) 
  end  
    
  def test_returns_false_if_comment_event_and_not_notifiying
    config = @config
    config['notify_comments'] = false
    assert_equal(
      false,
      service(:issue_comment, config, payload).receive_event,
      'Should not reported comment event'
    )
  end
    
  def test_returns_false_if_wiki_event_and_not_notifiying
    config = @config
    config['notify_wiki'] = false
    assert_equal(
      false,
      service(:gollum, config, payload).receive_event,
      'Should not reported wiki event'
    )
  end
    
  def test_returns_false_if_issue_event_and_not_notifiying
    config = @config
    config['notify_issue'] = false
    assert_equal(
      false,
      service(:issues, config, payload).receive_event,
      'Should not reported issues event'
    )
  end
    
  def test_returns_false_if_pull_event_and_not_notifiying
    config = @config
    config['notify_pull'] = false
    assert_equal(
      false,
      service(:pull_request_review_comment, config, payload).receive_event,
      'Should not reported pull event'
    )
  end
    
  def test_returns_false_if_deployment_event_and_not_notifiying
    config = @config
    config['notify_deployment'] = false
    assert_equal(
      false,
      service(:deployment_status, config, payload).receive_event,
      'Should not reported deployment event'
    )
  end
    
  def test_returns_false_if_team_event_and_not_notifiying
    config = @config
    config['notify_team'] = false
    assert_equal(
      false,
      service(:team_add, config, payload).receive_event,
      'Should not reported team event'
    )
  end
    
  def test_returns_false_if_team_event_and_not_notifiying
    config = @config
    config['notify_release'] = false
    assert_equal(
      false,
      service(:release, config, payload).receive_event,
      'Should not reported release event'
    )
  end
  def service(*args)
    super Service::XmppMuc, *args
  end
end