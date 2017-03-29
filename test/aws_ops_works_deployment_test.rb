require File.expand_path('../helper', __FILE__)

class AwsOpsWorksDeploymentTest < Service::TestCase
  include Service::HttpTestMethods

  def setup
    super
    AWS.stub!
  end

  def test_stack_id_sent
    response = aws_service.receive_event
    assert_equal sample_data['stack_id'], response.request_options[:stack_id]
  end

  def test_environmental_stack_id_sent
    svc = Service::AwsOpsWorks.new(:deployment, sample_data, environmental_payload)

    response = svc.receive_event
    stack_id = opsworks_deployment_environments['staging']['stack_id']
    assert_equal stack_id, response.request_options[:stack_id]
  end

  def test_stack_id_missing
    svc = aws_service(sample_data.except('stack_id'))
    assert_raises Service::ConfigurationError do
      svc.receive_event
    end
  end

  def test_app_id_sent
    response = aws_service.receive_event
    assert_equal sample_data['app_id'], response.request_options[:app_id]
  end

  def test_environmental_app_id_sent
    svc = Service::AwsOpsWorks.new(:deployment, sample_data, environmental_payload)
    response = svc.receive_event
    app_id = opsworks_deployment_environments['staging']['app_id']
    assert_equal app_id, response.request_options[:app_id]
  end

  def test_app_id_missing
    svc = aws_service(sample_data.except('app_id'))
    assert_raises Service::ConfigurationError do
      svc.receive_event
    end
  end

  def test_aws_access_key_id_configured
    config = aws_service.ops_works_client.config
    assert_equal sample_data['aws_access_key_id'], config.access_key_id
  end

  def test_aws_access_key_id_missing
    svc = aws_service(sample_data.except('aws_access_key_id'))
    assert_raises Service::ConfigurationError do
      svc.receive_event
    end
  end

  def test_aws_secret_access_key_configured
    config = aws_service.ops_works_client.config
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
      "target_url"  => "https://console.aws.amazon.com/opsworks/home?#/stack/12345678-1234-1234-1234-123456789012/deployments",
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
    app_id = opsworks_deployment_environments['staging']['app_id']
    assert_equal app_id, response.request_options[:app_id]

    @stubs.verify_stubbed_calls
  end

  def aws_service(data = sample_data, payload = sample_payload)
    Service::AwsOpsWorks.new(:deployment, data, payload)
  end

  def service_class
    Service::AwsOpsWorks
  end

  def sample_data
    {
      'aws_access_key_id'     => 'AKIA1234567890123456',
      'aws_secret_access_key' => '0123456789+0123456789+0123456789+0123456',
      'stack_id'              => '12345678-1234-1234-1234-123456789012',
      'app_id'                => '01234567-0123-0123-0123-012345678901',
      'branch_name'           => 'default-branch'
    }
  end

  def opsworks_deployment_environments
    {
      'staging' => {
        'app_id'   => '01234567-0123-0123-0123-012345678901',
        'stack_id' => '12345678-1234-1234-1234-123456789012',
      },
      'production' => {
        'app_id'   => '01234567-0123-0123-0123-012345678902',
        'stack_id' => '12345678-1234-1234-1234-123456789013',
      },
      'qa' => {
        'app_id'   => '01234567-0123-0123-0123-012345678903',
        'stack_id' => '12345678-1234-1234-1234-123456789012',
      }
    }
  end

  def environmental_payload
    custom_payload = {
      'environment' => 'staging',
      'payload' => {
        'config' => {
          'opsworks' => opsworks_deployment_environments
        }
      }
    }
    Service::DeploymentHelpers.sample_deployment_payload.merge(custom_payload)
  end

  def sample_payload(branch_name = 'default-branch')
    Service::DeploymentHelpers.sample_deployment_payload.merge('ref' => "refs/heads/#{branch_name}")
  end
end
