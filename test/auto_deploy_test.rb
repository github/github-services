require File.expand_path('../helper', __FILE__)

class AutoDeployTest < Service::TestCase
  include Service::HttpTestMethods

  def auto_deploy_on_push_service_data
    {
      'github_token' => github_token,
      'environments' => 'production'
    }
  end

  def auto_deploy_on_status_service_data
    auto_deploy_on_push_service_data.merge({'deploy_on_status' => '1'})
  end

  def auto_deploy_on_push_service
    service(:push, auto_deploy_on_push_service_data, push_payload)
  end
  
  def auto_deploy_on_status_service
    service(:status, auto_deploy_on_status_service_data, status_payload)
  end

  def test_unsupported_deployment_events
    exception = assert_raise(Service::ConfigurationError) do
      service(:deployment, auto_deploy_on_push_service_data, deployment_payload).receive_event
    end

    message = "The deployment event is currently unsupported."
    assert_equal message, exception.message
  end

  def test_push_deployment_configured_properly
    stub_github_repo_deployment_access

    github_post_body = {
      "ref"               => "a47fd41f",
      "environment"       => "production",
      "description"       => "Auto-Deployed by GitHub Services@7fc10c20 for rtomayko - master@a47fd41f",
      "required_contexts" => [ ],
    }

    github_deployment_path = "/repos/mojombo/grit/deployments"
    @stubs.post github_deployment_path do |env|
      assert_equal 'api.github.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      assert_equal github_post_body, JSON.parse(env[:body])
      [200, {}, '']
    end

    auto_deploy_on_push_service.receive_event
    @stubs.verify_stubbed_calls
  end
  
  def test_status_deployment_configured_properly
    stub_github_repo_deployment_access

    github_post_body = {
      "ref"               => "a47fd41f",
      "environment"       => "production",
      "description"       => "Auto-Deployed by GitHub Services@7fc10c20 for rtomayko - master@a47fd41f",
      "required_contexts" => [ ],
    }

    github_deployment_path = "/repos/mojombo/grit/deployments"
    @stubs.post github_deployment_path do |env|
      assert_equal 'api.github.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      assert_equal github_post_body, JSON.parse(env[:body])
      [200, {}, '']
    end

    auto_deploy_on_status_service.receive_event
    @stubs.verify_stubbed_calls
  end

  #def test_deployment_misconfigured
  #  stub_github_access

  #  @stubs.get "/repos/atmos/my-robot/tarball/9be5c2b9" do |env|
  #    [302, {'Location' => 'https://git.io/a'}, '']
  #  end

  #  github_post_body = {
  #  }

  #  github_deployment_path = "/repos/atmos/my-robot/deployments/721/statuses"
  #  @stubs.post github_deployment_path do |env|
  #    assert_equal 'api.github.com', env[:url].host
  #    assert_equal 'https', env[:url].scheme
  #    assert_equal github_post_body, JSON.parse(env[:body])
  #    [404, {}, '']
  #  end

  #  exception = assert_raise(Service::ConfigurationError) do
  #    auto_deploy_on_push_service.receive_event
  #  end
  #  @stubs.verify_stubbed_calls

  #  message = "Unable to update the deployment status on GitHub with the provided token."
  #  assert_equal message, exception.message
  #end

  def test_deployment_with_bad_github_user_credentials
    stub_github_user(404)

    exception = assert_raise(Service::ConfigurationError) do
      auto_deploy_on_push_service.receive_event
    end
    @stubs.verify_stubbed_calls

    message = "Unable to access GitHub with the provided token."
    assert_equal message, exception.message
  end

  def test_deployment_without_access_to_github_repo_deployments
    stub_github_repo_deployment_access(404)

    exception = assert_raise(Service::ConfigurationError) do
      auto_deploy_on_push_service.receive_event
    end
    @stubs.verify_stubbed_calls

    message = "Unable to access the mojombo/grit repository's deployments on GitHub with the provided token."
    assert_equal message, exception.message
  end

  def service_class
    Service::AutoDeploy
  end

  def stub_github_user(code = 200)
    @stubs.get "/user" do |env|
      assert_equal 'api.github.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      assert_equal "token #{github_token}", env[:request_headers]['Authorization']
      [code, {}, '']
    end
  end

  def stub_github_repo_deployment_access(code = 200, scopes = "repo:deployment, user")
    stub_github_user
    @stubs.get "/repos/mojombo/grit/deployments" do |env|
      assert_equal 'api.github.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      assert_equal "token #{github_token}", env[:request_headers]['Authorization']
      headers = {"X-OAuth-Scopes" => scopes }
      [code, headers, '']
    end
  end

  def github_token
    @github_token ||= SecureRandom.hex(24)
  end
end
