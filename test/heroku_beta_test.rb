require File.expand_path('../helper', __FILE__)

class HerokuBetaTest < Service::TestCase
  include Service::HttpTestMethods

  def heroku_service
    data = {
      'name'         => 'my-app',
      'heroku_token' => heroku_token,
      'github_token' => github_token
    }

    service(:deployment, data, deployment_payload)
  end

  def test_unsupported_push_events
    data = { 'name' => 'my-app' }
    exception = assert_raise(Service::ConfigurationError) do
      service(:push, data, push_payload).receive_event
    end

    message = "The push event is currently unsupported."
    assert_equal message, exception.message
  end

  def test_unsupported_status_events
    data = { 'name' => 'my-app' }
    exception = assert_raise(Service::ConfigurationError) do
      service(:status, data, push_payload).receive_event
    end

    message = "The status event is currently unsupported."
    assert_equal message, exception.message
  end

  def test_deployment_configured_properly
    stub_heroku_access
    stub_github_access

    @stubs.get "/repos/atmos/my-robot/tarball/9be5c2b9" do |env|
      [200, {'Location' => 'https://git.io/a'}, '']
    end

    post_body = {"source_blob" => {"url" => "https://git.io/a","version" => "master@9be5c2b9"}}

    @stubs.post "/apps/my-app/builds" do |env|
      assert_equal 'api.heroku.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      assert_equal post_body, JSON.parse(env[:body])
      [200, {}, '']
    end

    heroku_service.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_deployment_heroku_misconfigured
    stub_heroku_access(404)

    exception = assert_raise(Service::ConfigurationError) do
      heroku_service.receive_event
    end
    @stubs.verify_stubbed_calls

    message = "Unable to access my-app on heroku with the provided token."
    assert_equal message, exception.message
  end

  def test_deployment_with_bad_github_user_credentials
    stub_heroku_access
    stub_github_user(404)

    exception = assert_raise(Service::ConfigurationError) do
      heroku_service.receive_event
    end
    @stubs.verify_stubbed_calls

    message = "Unable to access GitHub with the provided token."
    assert_equal message, exception.message
  end

  def test_deployment_without_access_to_github_repo
    stub_heroku_access
    stub_github_access(404)

    exception = assert_raise(Service::ConfigurationError) do
      heroku_service.receive_event
    end
    @stubs.verify_stubbed_calls

    message = "Unable to access the atmos/my-robot repository on GitHub with the provided token."
    assert_equal message, exception.message
  end

  def service_class
    Service::HerokuBeta
  end

  def stub_github_user(code = 200)
    @stubs.get "/user" do |env|
      assert_equal 'api.github.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      assert_equal "token #{github_token}", env[:request_headers]['Authorization']
      [code, {}, '']
    end
  end

  def stub_github_access(code = 200, scopes = "repo, gist, user")
    stub_github_user
    @stubs.get "/repos/atmos/my-robot" do |env|
      assert_equal 'api.github.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      assert_equal "token #{github_token}", env[:request_headers]['Authorization']
      headers = {"X-OAuth-Scopes" => scopes }
      [code, headers, '']
    end
  end

  def stub_heroku_access(code = 200)
    @stubs.get "/apps/my-app" do |env|
      assert_equal 'api.heroku.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      assert_equal Base64.encode64(":#{heroku_token}"), env[:request_headers]['Authorization']
      [code, {}, '']
    end
  end

  def heroku_token
    @heroku_token ||= SecureRandom.hex(24)
  end

  def github_token
    @github_token ||= SecureRandom.hex(24)
  end
end
