require File.expand_path('../helper', __FILE__)

class AutoDeployTest < Service::TestCase
  include Service::HttpTestMethods

  def auto_deploy_on_push_service_data
    {
      'github_token'     => github_token,
      'environments'     => 'production',
      'deploy_on_status' => '0'
    }
  end

  def auto_deploy_on_status_service_data(options = { })
    auto_deploy_on_push_service_data.merge options.merge('deploy_on_status' => '1')
  end

  def auto_deploy_on_push_service
    service(:push, auto_deploy_on_push_service_data, push_payload)
  end

  def auto_deploy_on_status_service(options = { })
    service(:status, auto_deploy_on_status_service_data(options), status_payload)
  end

  def test_unsupported_deployment_events
    exception = assert_raises(Service::ConfigurationError) do
      service(:deployment, auto_deploy_on_push_service_data, deployment_payload).receive_event
    end

    message = "The deployment event is currently unsupported."
    assert_equal message, exception.message
  end

  def test_push_deployment_configured_properly
    stub_github_repo_deployment_access
    services_sha = Service.current_sha[0..7]

    github_post_body = {
      "ref"               => "a47fd41f",
      "payload"           => {"hi"=>"haters"},
      "environment"       => "production",
      "description"       => "Auto-Deployed on push by GitHub Services@#{services_sha} for rtomayko - master@a47fd41f",
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

  def test_push_deployment_configured_for_status
    stub_github_repo_deployment_access

    # successful push to default branch but configured for status deployments
    service(:push, auto_deploy_on_status_service_data, status_payload).receive_event
    @stubs.verify_stubbed_calls
  end

  def test_status_deployment_configured_properly
    stub_github_repo_deployment_access
    services_sha = Service.current_sha[0..7]

    github_post_body = {
      "ref"               => "7b80eb10",
      "payload"           => {"hi"=>"haters"},
      "environment"       => "production",
      "description"       => "Auto-Deployed on status by GitHub Services@#{services_sha} for rtomayko - master@7b80eb10",
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

  def test_status_deployment_configured_properly_on_enterprise
    services_sha = Service.current_sha[0..7]

    github_post_body = {
      "ref"               => "7b80eb10",
      "payload"           => {"hi"=>"haters"},
      "environment"       => "production",
      "description"       => "Auto-Deployed on status by GitHub Services@#{services_sha} for rtomayko - master@7b80eb10",
      "required_contexts" => [ ],
    }

    github_deployment_path = "/repos/mojombo/grit/deployments"
    @stubs.post github_deployment_path do |env|
      assert_equal 'enterprise.myorg.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      assert_equal github_post_body, JSON.parse(env[:body])
      [200, {}, '']
    end

    @stubs.get "/user" do |env|
      assert_equal 'enterprise.myorg.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      assert_equal "token #{github_token}", env[:request_headers]['Authorization']
      [200, {}, '']
    end

    deployment_history = [{'environment' => 'staging',    'id' => 42},
                          {'environment' => 'production', 'id' => 43, 'payload' => {'hi' => 'haters'}}].to_json

    @stubs.get "/repos/mojombo/grit/deployments" do |env|
      assert_equal 'enterprise.myorg.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      assert_equal "token #{github_token}", env[:request_headers]['Authorization']
      headers = {"X-OAuth-Scopes" => "repo,deployment" }
      [200, headers, deployment_history]
    end

    auto_deploy_on_status_service('github_api_url' => 'https://enterprise.myorg.com').receive_event
    @stubs.verify_stubbed_calls
  end

  def test_status_deployment_configured_with_failure_status
    stub_github_repo_deployment_access

    # don't do anything on failed states
    failed_status_payload = status_payload.merge('state' => 'failure')
    service(:status, auto_deploy_on_status_service_data, failed_status_payload).receive_event
    @stubs.verify_stubbed_calls
  end

  def test_status_deployment_configured_for_push
    stub_github_repo_deployment_access

    # successful commit status but configured for push
    service(:status, auto_deploy_on_push_service_data, status_payload).receive_event
    @stubs.verify_stubbed_calls
  end

  def test_deployment_with_bad_github_user_credentials
    stub_github_user(404)

    exception = assert_raises(Service::ConfigurationError) do
      auto_deploy_on_push_service.receive_event
    end
    @stubs.verify_stubbed_calls

    message = "Unable to access GitHub with the provided token."
    assert_equal message, exception.message
  end

  def test_deployment_without_access_to_github_repo_deployments
    stub_github_repo_deployment_access(404)

    exception = assert_raises(Service::ConfigurationError) do
      auto_deploy_on_push_service.receive_event
    end
    @stubs.verify_stubbed_calls

    message = "Unable to access the mojombo/grit repository's deployments on GitHub with the provided token."
    assert_equal message, exception.message
  end

  def test_slashed_payload_ref
    payload = { 'ref' => 'refs/heads/slash/test' }
    service = Service::AutoDeploy.new(:push, {}, payload)
    assert_equal 'slash/test', service.payload_ref
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
    deployment_history = [{'environment' => 'staging',    'id' => 42},
                          {'environment' => 'production', 'id' => 43, 'payload' => {'hi' => 'haters'}}].to_json

    @stubs.get "/repos/mojombo/grit/deployments" do |env|
      assert_equal 'api.github.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      assert_equal "token #{github_token}", env[:request_headers]['Authorization']
      headers = {"X-OAuth-Scopes" => scopes }
      [code, headers, deployment_history]
    end
  end

  def github_token
    @github_token ||= SecureRandom.hex(24)
  end
end
