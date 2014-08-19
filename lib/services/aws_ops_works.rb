require 'aws/ops_works'

class Service::AwsOpsWorks < Service::HttpPost
  self.title = 'AWS OpsWorks'

  string     :app_id,               # see AppId at http://docs.aws.amazon.com/opsworks/latest/APIReference/API_App.html
             :stack_id,             # see StackId at http://docs.aws.amazon.com/opsworks/latest/APIReference/API_Stack.html
             :branch_name,          # see Revision at http://docs.aws.amazon.com/opsworks/latest/APIReference/API_Source.html
             :aws_access_key_id     # see AWSAccessKeyID at http://docs.aws.amazon.com/opsworks/latest/APIReference/CommonParameters.html
  password   :aws_secret_access_key

  white_list :app_id,
             :stack_id,
             :branch_name,
             :aws_access_key_id

  default_events :push, :deployment
  url "http://docs.aws.amazon.com/opsworks/latest/APIReference/API_CreateDeployment.html"

  def app_id
    environment_app_id || required_config_value('app_id')
  end

  def stack_id
    environment_stack_id || required_config_value('stack_id')
  end

  def deployment_command
    payload['task'] || 'deploy'
  end

  def environment_stack_id
    opsworks_payload_environment('stack_id')
  end

  def environment_app_id
    opsworks_payload_environment('app_id')
  end

  def opsworks_payload_environment(key)
    opsworks_payload && opsworks_payload[environment] && opsworks_payload[environment][key]
  end

  def opsworks_payload
    payload['payload'] && payload['payload']['config'] && payload['payload']['config']['opsworks']
  end

  def environment
    payload['environment']
  end

  def receive_event
    case event.to_s
    when 'deployment'
      update_app_revision(ref_name)
      create_deployment
    when 'push'
      if branch_name == required_config_value('branch_name')
        create_deployment
      end
    else
      raise_config_error("The #{event} event is currently unsupported.")
    end
  end

  def configured_branch_name
    required_config_value('branch_name')
  end

  def ref_name
    payload['ref']
  end

  def update_app_revision(revision_name)
    ops_works_client.update_app app_id: app_id, app_source: { revision: revision_name }
  end

  def create_deployment
    ops_works_client.create_deployment stack_id: stack_id, app_id: app_id,
                                       command:  { name: deployment_command }
  end

  def ops_works_client
    AWS::OpsWorks::Client.new access_key_id:     required_config_value('aws_access_key_id'),
                              secret_access_key: required_config_value('aws_secret_access_key')
  end
end
