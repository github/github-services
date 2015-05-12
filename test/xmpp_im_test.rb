class XmppImTest < Service::TestCase
  class MockXmpp4r

    def send(message)
      @messages = [] if @messages.nil?
      @messages.push message
    end
      
    def get_messages
        @messages
    end
      
    def connect(host, port)
      @host = host
      @port = port
    end
      
    def get_host
      @host
    end
      
    def get_port
      @port
    end

    def close
        
    end

  end

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
      
    @config = {
      'JID' => 'me@example.com',
      'password' => 'password',
      'receivers' => 'bare@server full@server/resource',
      'notify_fork' => '1',
      'notify_wiki' => '1',
      'notify_comments' => '1',
      'notify_watch' => '1',
      'notify_issue' => '1',
      'notify_pull' => '1',
      'is_test' => true
    }
    @mock = MockXmpp4r.new()
  end
    
  def service(*args)
    xmppIm = super Service::XmppIm, *args
    xmppIm.set_connection @mock
    xmppIm
  end

  def test_no_jid_provided
    assert_raises(Service::ConfigurationError, 'JID is required') do
      config = @config
      config['JID'] = ''
      service(config, payload).receive_event
    end
  end

  def test_no_password_provided
    assert_raises(Service::ConfigurationError, 'Password is required') do
      config = @config
      config['password'] = ''
      service(config, payload).receive_event
    end
  end

  def illegal_jid_throws_error
    assert_raises(Service::ConfigurationError, 'Illegal receiver JID') do
      config = @config
      config['receivers'] = 'bare@server illegal@server@what?'
      service(config, payload).receive_event
    end
  end
    
  def test_errors_on_bad_port
    assert_raises(Service::ConfigurationError, 'XMPP port must be numeric') do
      config = @config
      config['port'] = 'PORT NUMBER'
      service(config, payload).receive_event
    end
  end
    
  def sets_custom_port
    config = @config
    port = '1234'
    config['port'] = port
    service(config, payload).receive_event
    assert_equal(Integer(port), @mock.get_port)
  end
    
  def sets_custom_host
    config = @config
    host = 'github.com'
    config['host'] = host
    service(config, payload).receive_event
    assert_equal(host, @mock.get_host)
  end
    
  def uses_default_host
    config = @config
    service(config, payload).receive_event
    assert_true(@mock.get_host.nil?) 
  end
    
  def uses_default_port
    config = @config
    service(config, payload).receive_event
    assert_equal(5222, @mock.get_port)
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
    
  def test_returns_true_if_part_matched_filtered_branch
    config = @config
    config['filter_branch'] = 'ast'
    assert_equal(
      true,
      service(config, payload).receive_event,
      'Should not have filtered this branch'
    )  
  end
    
  def test_returns_false_if_fork_event_and_not_notifiying
    config = @config
    config['notify_fork'] = '0'
    assert_equal(
      false,
      service(:fork, config, payload).receive_event,
      'Should not reported fork event'
    ) 
  end
    
  def test_returns_false_if_watch_event_and_not_notifiying
    config = @config
    config['notify_watch'] = '0'
    assert_equal(
      false,
      service(:watch, config, payload).receive_event,
      'Should not reported watch event'
    ) 
  end  
    
  def test_returns_false_if_comment_event_and_not_notifiying
    config = @config
    config['notify_comments'] = '0'
    assert_equal(
      false,
      service(:issue_comment, config, payload).receive_event,
      'Should not reported comment event'
    )
  end
    
  def test_returns_false_if_wiki_event_and_not_notifiying
    config = @config
    config['notify_wiki'] = '0'
    assert_equal(
      false,
      service(:gollum, config, payload).receive_event,
      'Should not reported wiki event'
    )
  end
    
  def test_returns_false_if_issue_event_and_not_notifiying
    config = @config
    config['notify_issue'] = '0'
    assert_equal(
      false,
      service(:issues, config, payload).receive_event,
      'Should not reported issues event'
    )
  end
    
  def test_returns_false_if_pull_event_and_not_notifiying
    config = @config
    config['notify_pull'] = '0'
    assert_equal(
      false,
      service(:pull_request_review_comment, config, payload).receive_event,
      'Should not reported pull event'
    )
  end

  def test_generates_expected_push_message
      config = @config
      message = ''
      service(:push, config, payload).receive_event
      assert_equal(
          8,
          @mock.get_messages().length,
          'Expected 8 messages'
      )
      assert_equal(
          "[grit] @rtomayko pushed 3 new commits to master: http://github.com/mojombo/grit/compare/4c8124f...a47fd41",
          @mock.get_messages()[0].body,
          'Expected push message not received'
      )
      assert_equal(
          "[grit/master] stub git call for Grit#heads test f:15 Case#1 - Tom Preston-Werner",
          @mock.get_messages()[1].body,
          'Expected push message not received'
      )
      assert_equal(
          "[grit/master] clean up heads test f:2hrs - Tom Preston-Werner",
          @mock.get_messages()[2].body,
          'Expected push message not received'
      )
      assert_equal(
          "[grit/master] add more comments throughout - Tom Preston-Werner",
          @mock.get_messages()[3].body,
          'Expected push message not received'
      )
  end

  def test_generates_error_if_push_message_cant_be_generated 
    assert_raises(Service::ConfigurationError, /Unable to build message/) do
      service(:commit_comment, @config, {}).receive_event
    end
  end

  def test_sends_messages_to_expected_jids
    service(:commit_comment, @config, commit_comment_payload).receive_event
      assert_equal(
          2,
          @mock.get_messages().length,
          'Expected 2 messages'
      )
      assert_equal(
          ::Jabber::JID.new('full@server/resource'),
          @mock.get_messages()[1].to
      )
      assert_equal(
          ::Jabber::JID.new('bare@server'),
          @mock.get_messages()[0].to
      )
  end
    
  def test_generates_expected_commit_comment_message
      message = '[grit] @defunkt commented on commit 441e568: this... https://github.com/mojombo/magik/commit/441e5686a726b79bcdace639e2591a60718c9719#commitcomment-3332777'
      service(:commit_comment, @config, commit_comment_payload).receive_event
      assert_equal(
          2,
          @mock.get_messages().length,
          'Expected 2 messages'
      )
      assert_equal(
          message,
          @mock.get_messages()[0].body,
          'Expected commit comment message not received'
      )
  end
    
  def test_generates_error_if_commit_comment_message_cant_be_generated 
    assert_raises(Service::ConfigurationError, /Unable to build message/) do
      service(:commit_comment, @config, {}).receive_event
    end
  end
    
  def test_generates_expected_issue_comment_message
      message = '[grit] @defunkt commented on issue #5: this... '
      service(:issue_comment, @config, issue_comment_payload).receive_event
      assert_equal(
          2,
          @mock.get_messages().length,
          'Expected 2 messages'
      )
      assert_equal(
          message,
          @mock.get_messages()[0].body,
          'Expected issue comment message not received'
      )
  end

  def test_generates_error_if_issue_comment_message_cant_be_generated 
    assert_raises(Service::ConfigurationError, /Unable to build message/) do
      service(:issue_comment, @config, {}).receive_event
    end
  end
    
  def test_generates_expected_issues_message
      message = '[grit] @defunkt opened issue #5: booya '
      service(:issues, @config, issues_payload).receive_event
      assert_equal(
          2,
          @mock.get_messages().length,
          'Expected 2 messages'
      )
      assert_equal(
          message,
          @mock.get_messages()[0].body,
          'Expected issues message not received'
      )
  end

  def test_generates_error_if_issues_message_cant_be_generated 
    assert_raises(Service::ConfigurationError, /Unable to build message/) do
      service(:issues, @config, {}).receive_event
    end
  end
    
  def test_generates_expected_pull_request_message
      message = '[grit] @defunkt opened pull request #5: booya (master...feature) https://github.com/mojombo/magik/pulls/5'
      service(:pull_request, @config, pull_request_payload).receive_event
      assert_equal(
          2,
          @mock.get_messages().length,
          'Expected 2 messages'
      )
      assert_equal(
          message,
          @mock.get_messages()[0].body,
          'Expected pull request message not received'
      )
  end

  def test_generates_error_if_pull_request_message_cant_be_generated 
    assert_raises(Service::ConfigurationError, /Unable to build message/) do
      payload = pull_request_payload
      payload['pull_request']['base'] = {}
      service(:pull_request, @config, payload).receive_event
    end
  end
    
  def test_generates_expected_pull_request_review_comment_message
      message = '[grit] @defunkt commented on pull request #5 03af7b9: very... https://github.com/mojombo/magik/pull/5#discussion_r18785396'
      service(:pull_request_review_comment, @config, pull_request_review_comment_payload).receive_event
      assert_equal(
          2,
          @mock.get_messages().length,
          'Expected 2 messages'
      )
      assert_equal(
          message,
          @mock.get_messages()[0].body,
          'Expected pull request review comment message not received'
      )
  end

  def test_generates_error_if_pull_request_review_comment_message_cant_be_generated 
    assert_raises(Service::ConfigurationError, /Unable to build message/) do
      service(:pull_request_review_comment, @config, {}).receive_event
    end
  end
    
  def test_generates_expected_gollum_message
      message = '[grit] @defunkt modified 1 page https://github.com/mojombo/magik/wiki/Foo'
      service(:gollum, @config, gollum_payload).receive_event
      assert_equal(
          4,
          @mock.get_messages().length,
          'Expected 4 messages'
      )
      assert_equal(
          message,
          @mock.get_messages()[0].body,
          'Expected wiki edit summmary message not received'
      )
      assert_equal(
          'User created page "Foo" https://github.com/mojombo/magik/wiki/Foo',
          @mock.get_messages()[1].body,
          'Expected wiki page edit not received'
      )
  end

  def test_generates_error_if_gollum_cant_be_generated 
    assert_raises(Service::ConfigurationError, /Unable to build message/) do
      service(:gollum, @config, {}).receive_event
    end
  end
 
end
