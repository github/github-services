require File.expand_path('../helper', __FILE__)

class AwsOpsWorksTest < Service::TestCase

  def setup
    AWS.stub!
  end

  def test_stack_id_sent
    response = service.receive_event
    assert_equal sample_data['stack_id'], response.request_options[:stack_id]
  end

  def test_stack_id_missing
    svc = service(sample_data.except('stack_id'))
    assert_raise Service::ConfigurationError do
      svc.receive_event
    end
  end

  def test_app_id_sent
    response = service.receive_event
    assert_equal sample_data['app_id'], response.request_options[:app_id]
  end

  def test_app_id_missing
    svc = service(sample_data.except('app_id'))
    assert_raise Service::ConfigurationError do
      svc.receive_event
    end
  end

  def test_expected_branch_name_received
    response = service.receive_event
    assert_not_nil response
  end

  def test_unexpected_branch_name_received
    response = service(sample_data, sample_payload('another-branch')).receive_event
    assert_nil response
  end

  def test_branch_name_missing
    svc = service(sample_data.except('branch_name'))
    assert_raise Service::ConfigurationError do
      svc.receive_event
    end
  end

  def test_aws_access_key_id_configured
    config = service.ops_works_client.config
    assert_equal sample_data['aws_access_key_id'], config.access_key_id
  end

  def test_aws_access_key_id_missing
    svc = service(sample_data.except('aws_access_key_id'))
    assert_raise Service::ConfigurationError do
      svc.receive_event
    end
  end

  def test_aws_secret_access_key_configured
    config = service.ops_works_client.config
    assert_equal sample_data['aws_secret_access_key'], config.secret_access_key
  end

  def test_aws_secret_access_key_missing
    svc = service(sample_data.except('aws_secret_access_key'))
    assert_raise Service::ConfigurationError do
      svc.receive_event
    end
  end

  def service(data = sample_data, payload = sample_payload)
    Service::AwsOpsWorks.new(:push, data, payload)
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

  def sample_payload(branch_name = 'default-branch')
    Service::PushHelpers.sample_payload.merge('ref' => "refs/heads/#{branch_name}")
  end

end
