require File.expand_path('../helper', __FILE__)

class TestTrackTest < Service::TestCase
  include Service::HttpTestMethods

  @@test_server_url = 'http://example.com/cgi-bin/ttextpro.exe'
  @@test_provider_key = '{aa858562-025a-4236-9bf2-6cf4c81e0468}:{63e3869c-7780-4915-9d46-632dbb287b60}'

  # Test a normal push with all required data
  def test_push
    data = {
      'server_url' => @@test_server_url,
      'provider_key' => @@test_provider_key
    }

    @stubs.post '/cgi-bin/ttextpro.exe?action=AddGitHubAttachment' do |env|
      body = JSON.parse(env[:body])

      assert_equal 'http://example.com/cgi-bin/ttextpro.exe?action=AddGitHubAttachment', env[:url].to_s
      assert_equal data, body['config']
      assert_equal 'push', body['event']

      [200, {}, JSON.dump({ 'errorCode' => 0, 'errorMessage' => '' })]
    end

    svc = service(data, payload)
    svc.receive_push
    @stubs.verify_stubbed_calls
  end

  # Test a push with missing required configuration data
  def test_config_errors
    # server url missing
    assert_raises Service::ConfigurationError do
      svc = service({ 'server_url' => '',
        'provider_key' => @@test_provider_key }, payload)
      svc.receive_push
    end

    # provider key missing
    assert_raises Service::ConfigurationError do
      svc = service({ 'server_url' => @@test_server_url,
        'provider_key' => '' }, payload)
      svc.receive_push
    end

    # forbidden [] characters in tag
    assert_raises Service::ConfigurationError do
      svc = service({ 'server_url' => @@test_server_url,
        'provider_key' => @@test_provider_key,
        'issue_tag' => '[has a bracket]' }, payload)
      svc.receive_push
    end

    # forbidden - character in tag
    assert_raises Service::ConfigurationError do
      svc = service({ 'server_url' => @@test_server_url,
        'provider_key' => @@test_provider_key,
        'issue_tag' => 'has a-dash' }, payload)
      svc.receive_push
    end
  end

  # Test error response from service
  def test_service_failure
    data = {
      'server_url' => @@test_server_url,
      'provider_key' => @@test_provider_key
    }

    @stubs.post '/cgi-bin/ttextpro.exe?action=AddGitHubAttachment' do |env|
      [200, {}, JSON.dump({ 'errorCode' => 3, 'errorMessage' => 'The provider key was not recognized.' })]
    end

    assert_raises Service::ConfigurationError do
      svc = service(data, payload)
      svc.receive_push
    end
  end

  def service_class
    Service::TestTrack
  end
end

