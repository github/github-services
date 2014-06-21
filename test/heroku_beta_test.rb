require File.expand_path('../helper', __FILE__)

class HerokuBetaTest < Service::TestCase
  include Service::HttpTestMethods

  def heroku_service
    data = {
      'name'         => 'my-app',
      'heroku_token' => heroku_token,
      'github_token' => github_token
    }

    service(data, deployment_payload)
  end

  def test_deployment_configured_properly
    stub_heroku_access
    stub_github_access

    uri = Addressable::URI.parse("https://169.254.1.1/events")
    @stubs.post uri.path do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host,   uri.host
      assert_equal 'my-app',         body['config']['name']
      assert_equal heroku_token,     body['config']['heroku_token']
      assert_equal github_token,     body['config']['github_token']
      assert_equal "atmos/my-robot", body['payload']['name']
      assert_equal "master",         body['payload']['ref']
      assert_equal "9be5c2b9",       body['payload']['sha'][0..7]
      assert_equal "production",     body['payload']['environment']
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

  def test_deployment_with_misconfigured_gist_scope
    stub_heroku_access
    stub_github_access(200, "repo, user")

    exception = assert_raise(Service::ConfigurationError) do
      heroku_service.receive_event
    end
    @stubs.verify_stubbed_calls

    message = "No gist scope for your GitHub token, check the scopes of your personal access token."
    assert_equal message, exception.message
  end

  def service_class
    Service::HerokuBeta
  end

  def stub_github_user(code = 200)
    @stubs.get "/user" do |env|
      assert_equal env[:url].host, "api.github.com"
      assert_equal "token #{github_token}", env[:request_headers]['Authorization']
      [code, {}, '']
    end
  end

  def stub_github_access(code = 200, scopes = "repo, gist, user")
    stub_github_user
    @stubs.get "/repos/atmos/my-robot" do |env|
      assert_equal env[:url].host, "api.github.com"
      assert_equal "token #{github_token}", env[:request_headers]['Authorization']
      headers = {"X-OAuth-Scopes" => scopes }
      [code, headers, '']
    end
  end

  def stub_heroku_access(code = 200)
    @stubs.get "/apps/my-app" do |env|
      assert_equal env[:url].host, "api.heroku.com"
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
