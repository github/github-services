class XmppMucTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
      
    @config = {
      'JID' => 'me@example.com',
      'password' => 'password',
      'room' => 'status',
      'server' => 'muc.example.com',
      'nickname' => 'github',
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

  def test_no_password_provided
    assert_raise_with_message(Service::ConfigurationError, 'Server is required') do
      config = @config
      config['server'] = ''
      service(config, payload).receive_event
    end
  end

  def service(*args)
    super Service::XmppMuc, *args
  end
end