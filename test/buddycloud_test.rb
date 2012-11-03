require File.expand_path('../helper', __FILE__)

class BuddycloudTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @options = {'buddycloud_base_api' => 'https://api.buddycloud.org'}
  end

  def test_no_api_url_provided
    assert_raises Service::ConfigurationError do
      service({}, payload).receive_push
    end
  end

  def test_empty_api_url_provided
    assert_raises Service::ConfigurationError do
      service({'buddycloud_base_api' => ''}, payload).receive_push
    end
  end

  def test_no_username_provided
    assert_raises Service::ConfigurationError do
      service({'buddycloud_base_api' => 'https://api.buddycloud.org'}, payload).receive_push
    end
  end

  def test_empty_username_provided
    assert_raises Service::ConfigurationError do
      service({'buddycloud_base_api' => 'https://api.buddycloud.org', 'username' => ''}, payload).receive_push
    end
  end

  def test_no_password_provided
    assert_raises Service::ConfigurationError do
      service({
        'buddycloud_base_api' => 'https://api.buddycloud.org',
          'username'          => 'user@buddycloud.org'
      }, payload).receive_push
    end
  end

  def test_empty_password_provided
    assert_raises Service::ConfigurationError do
      service({
        'buddycloud_base_api' => 'https://api.buddycloud.org',
          'username'          => 'user@buddycloud.org',
          'password'          => ''
      }, payload).receive_push
    end
  end

  def test_no_channel_provided
    assert_raises Service::ConfigurationError do
      service({
        'buddycloud_base_api' => 'https://api.buddycloud.org',
          'username'          => 'user@buddycloud.org',
          'password'          => 'tellnoone',
      }, payload).receive_push
    end
  end

  def test_empty_channel_provided
    assert_raises Service::ConfigurationError do
      service({
        'buddycloud_base_api' => 'https://api.buddycloud.org',
          'username'          => 'user@buddycloud.org',
          'password'          => 'tellnoone',
          'channel'           => ''
      }, payload).receive_push
    end
  end

  def service(*args)
    super Service::Buddycloud, *args
  end
end
