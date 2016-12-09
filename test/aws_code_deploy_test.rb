require File.expand_path('../helper', __FILE__)
ENV['CODE_DEPLOY_STUB_RESPONSES'] = 'true'

class AwsCodeDeployDeploymentTest < Service::TestCase
  include Service::HttpTestMethods

  def setup
    super
  end

  def test_deployment_group_sent
    response = aws_service.receive_event
    assert_equal sample_data['deployment_group'], response.context[:deployment_group]
  end

  def test_environmental_deployment_group_sent
    svc = Service::AwsCodeDeploy.new(:deployment, sample_data, environmental_payload)

    response = svc.receive_event
    deployment_group = code_deploy_deployment_environments['staging']['deployment_group']
    assert_equal deployment_group, response.context[:deployment_group]
  end

  def test_application_name_sent
    svc = Service::AwsCodeDeploy.new(:deployment, sample_data, environmental_payload)
    response = svc.receive_event
    application_name = code_deploy_deployment_environments['staging']['application_name']
    assert_equal application_name, response.context[:application_name]
  end

  def test_environmental_application_name_sent
    svc = Service::AwsCodeDeploy.new(:deployment, sample_data, environmental_payload)
    response = svc.receive_event
    application_name = code_deploy_deployment_environments['staging']['application_name']
    assert_equal application_name, response.context[:application_name]
  end

  def test_application_name_missing
    svc = aws_service(sample_data.except('application_name'))
    assert_raises Service::ConfigurationError do
      svc.receive_event
    end
  end

  def test_aws_access_key_id_configured
    config = aws_service.code_deploy_client.config
    assert_equal sample_data['aws_access_key_id'], config.access_key_id
  end

  def test_aws_access_key_id_missing
    svc = aws_service(sample_data.except('aws_access_key_id'))
    assert_raises Service::ConfigurationError do
      svc.receive_event
    end
  end

  def test_aws_secret_access_key_configured
    config = aws_service.code_deploy_client.config
    assert_equal sample_data['aws_secret_access_key'], config.secret_access_key
  end

  def test_aws_secret_access_key_missing
    svc = aws_service(sample_data.except('aws_secret_access_key'))
    assert_raises Service::ConfigurationError do
      svc.receive_event
    end
  end

  def test_github_deployment_status_callbacks
    github_post_body = {
      "state"       => "success",
      "target_url"  => "https://console.aws.amazon.com/codedeploy/home?region=us-east-1#/deployments",
      "description" => "Deployment 721 Accepted by Amazon. (github-services@#{Service.current_sha[0..7]})"
    }

    github_deployment_path = "/repos/atmos/my-robot/deployments/721/statuses"
    @stubs.post github_deployment_path do |env|
      assert_equal 'api.github.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      assert_equal github_post_body, JSON.parse(env[:body])
      [200, {}, '']
    end

    custom_sample_data = sample_data.merge('github_token' => 'secret')
    svc = service(:deployment, custom_sample_data, environmental_payload)
    response = svc.receive_event
    application_name = code_deploy_deployment_environments['staging']['application_name']
    assert_equal application_name, response.context[:application_name]

    @stubs.verify_stubbed_calls
  end

  def aws_service(data = sample_data, payload = sample_payload)
    Service::AwsCodeDeploy.new(:deployment, data, payload)
  end

  def service_class
    Service::AwsCodeDeploy
  end

  def sample_data
    {
      'aws_access_key_id'     => 'AKIA1234567890123456',
      'aws_secret_access_key' => '0123456789+0123456789+0123456789+0123456',
      'application_name'      => 'testapp',
      'deployment_group_name' => 'production'
    }
  end

  def code_deploy_deployment_environments
    {
      'staging' => {
      },
      'production' => {
      }
    }
  end

  def environmental_payload
    custom_payload = {
      'environment' => 'staging',
      'payload' => {
        'config' => {
          'aws_code_deploy' => code_deploy_deployment_environments
        }
      }
    }
    Service::DeploymentHelpers.sample_deployment_payload.merge(custom_payload)
  end

  def sample_payload(branch_name = 'default-branch')
    Service::DeploymentHelpers.sample_deployment_payload.merge('ref' => "refs/heads/#{branch_name}")
  end
end
