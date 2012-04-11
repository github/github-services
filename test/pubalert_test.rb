require File.expand_path('../helper', __FILE__)

class PubAlertInValidEmailTests < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_public_alert_with_invalid_notify_email_hook_param
    callback_for_public_event = 'handle_public_event/'
    data = {'remote_url'   => "http://127.0.0.1:8000/#{callback_for_public_event}",
            'auth_token' => 'at',
            'repo_name' => 'r',
            'notify_email' => 'invalidemailaddress'}
    svc = service :public, data

    @stubs.post "/#{callback_for_public_event}" do |env|
      assert_equal 'public', env[:request_headers]['x-github-event']
      assert_match /form/, env[:request_headers]['content-type']
      assert_equal '127.0.0.1', env[:url].host
      assert_nil env[:request_headers]['X-Hub-Signature']
      [200, {}, '']
    end

    exception = assert_raise(Service::ConfigurationError) { svc.receive_public}
    assert(exception.message.include? "Not able to shoot email to #{data['notify_email']}")
    assert_equal svc.messages.size, 0
  end

  def service(*args)
    svc = super Service::PubAlert, *args
    def svc.messages
      @messages ||= []
    end

    def svc.notify_event(address, repo_name)
      my = self
      Mail.defaults do
        delivery_method :smtp, { :address   => my.email_config['address'],
                             :port      => my.email_config['port'],
                             :domain    => my.email_config['domain'],
                             :user_name => my.email_config['user_name'],
                             :password  => my.email_config['password'],
                             :authentication => my.email_config['authentication'],
                             :enable_starttls_auto => my.email_config['enable_starttls_auto']}

      end
      mail_message = Mail.deliver do
        to       address
        from     "GitHub <noreply@github.com>"
        reply_to "GitHub <noreply@github.com>"
        subject  "#{repo_name} is open-sourced."
        text_part do
          content_type 'text/plain; charset=UTF-8'
          body         "#{repo_name} is open-sourced."
        end
      end
      messages << mail_message
    end
    svc
  end
end

class PubAlertTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_empty_remote_url_hook_param
    svc = service :public, {}
    exception = assert_raise(Service::ConfigurationError) { svc.receive_public}
    assert_match /Missing 'remote_url'/, exception.message
  end

  def test_empty_auth_token_hook_param
    data = {'remote_url' => 'a'}
    svc = service :public, data
    exception = assert_raise(Service::ConfigurationError) { svc.receive_public}
    assert_match /Missing 'auth_token'/, exception.message
  end

  def test_empty_repo_name_hook_param
    data = {'remote_url' => 'a', 'auth_token' => 'b'}
    svc = service :public, data
    exception = assert_raise(Service::ConfigurationError) { svc.receive_public}
    assert_match /Missing 'repo_name'/, exception.message
  end

  def test_public_alert_without_notify_email_hook_param
    callback_for_public_event = 'handle_public_event/'
    data = {'remote_url'   => "http://127.0.0.1:8000/#{callback_for_public_event}",
            'auth_token' => 'at',
            'repo_name' => 'r',
            'notify_email' => ''}
    svc = service :public, data

    @stubs.post "/#{callback_for_public_event}" do |env|
      assert_equal 'public', env[:request_headers]['x-github-event']
      assert_match /form/, env[:request_headers]['content-type']
      assert_equal '127.0.0.1', env[:url].host
      assert_nil env[:request_headers]['X-Hub-Signature']
      [200, {}, '']
    end
    assert_nothing_raised(Service::ConfigurationError) { svc.receive_public }
    assert_equal svc.messages.size, 0
  end

  def test_public_alert_with_valid_hook_params
    callback_for_public_event = 'handle_public_event/'
    data = {'remote_url'   => "http://127.0.0.1:8000/#{callback_for_public_event}",
            'auth_token'   => 'sometoken',
            'repo_name'    => 'testrepo',
            'notify_email' => 'xyz@domain.com'}

    svc = service :public, data

    @stubs.post "/#{callback_for_public_event}" do |env|
      assert_equal 'public', env[:request_headers]['x-github-event']
      assert_match /form/, env[:request_headers]['content-type']
      assert_equal '127.0.0.1', env[:url].host
      assert_nil env[:request_headers]['X-Hub-Signature']
      [200, {}, '']
    end

    svc.receive_public

    assert svc.messages
    assert_equal svc.messages.size, 1
    msg = svc.messages.shift
    assert msg
    assert_equal msg['to'], data['notify_email']
    assert_equal msg['from'], "GitHub <noreply@github.com>"
    assert_equal msg['reply_to'], "GitHub <noreply@github.com>"
    assert_equal msg['subject'], "#{data['repo_name']} is open-sourced."
    assert_equal msg['body'], "#{data['repo_name']} is open-sourced."
  end

  def test_public_alert_with_multiple_email_addresses_in_notify_email
    callback_for_public_event = 'handle_public_event/'
    data = {'remote_url'   => "http://127.0.0.1:8000/#{callback_for_public_event}",
            'auth_token'   => 'sometoken',
            'repo_name'    => 'testrepo',
            'notify_email' => 'xyz@domain.com domain@xyz.com'}

    svc = service :public, data

    @stubs.post "/#{callback_for_public_event}" do |env|
      assert_equal 'public', env[:request_headers]['x-github-event']
      assert_match /form/, env[:request_headers]['content-type']
      assert_equal '127.0.0.1', env[:url].host
      assert_nil env[:request_headers]['X-Hub-Signature']
      [200, {}, '']
    end

    svc.receive_public

    assert svc.messages
    assert_equal svc.messages.size, 1
    msg = svc.messages.shift
    assert msg
    assert_equal msg['to'], 'xyz@domain.com'
    assert_equal msg['from'], "GitHub <noreply@github.com>"
    assert_equal msg['reply_to'], "GitHub <noreply@github.com>"
    assert_equal msg['subject'], "#{data['repo_name']} is open-sourced."
    assert_equal msg['body'], "#{data['repo_name']} is open-sourced."
  end

  #def test_public_alert_with_invalid_remote_url_hook_param
  #  data = {'remote_url'   => "somedomain",
  #          'auth_token' => 'at',
  #          'repo_name' => 'r',
  #          'notify_email' => ''}
  #  svc = service :public, data

  #  @stubs.post "/foo" do |env|
  #    assert_equal 'public', env[:request_headers]['x-github-event']
  #    assert_match /form/, env[:request_headers]['content-type']
  #    assert_equal 'somedomain.com', env[:url].host
  #    assert_nil env[:request_headers]['X-Hub-Signature']
  #    [200, {}, '']
  #  end

  #  exception = assert_raise(URI::Error) { svc.receive_public}
  #  assert(exception.message.include? "Not able to send a POST request to #{data['remote_url']}")
  #  assert_equal svc.messages.size, 0
  #end

  def service(*args)
    svc = super Service::PubAlert, *args
    def svc.messages
      @messages ||= []
    end

    def svc.notify_event(address, repo_name)
       messages << {'to' => address,
                     'from' => "GitHub <noreply@github.com>",
                     'reply_to' => "GitHub <noreply@github.com>",
                     'subject' => "#{repo_name} is open-sourced.",
                     'body' => "#{repo_name} is open-sourced."}
    end
    svc
  end
end
