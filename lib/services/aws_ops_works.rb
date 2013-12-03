require 'aws/ops_works'

class Service::AwsOpsWorks < Service::HttpPost
  self.title = 'AWS OpsWorks'

  string     :stack_id,             # see StackId at http://docs.aws.amazon.com/opsworks/latest/APIReference/API_Stack.html
             :app_id,               # see AppId at http://docs.aws.amazon.com/opsworks/latest/APIReference/API_App.html
             :branch_name,          # see Revision at http://docs.aws.amazon.com/opsworks/latest/APIReference/API_Source.html
             :aws_access_key_id     # see AWSAccessKeyID at http://docs.aws.amazon.com/opsworks/latest/APIReference/CommonParameters.html
  password   :aws_secret_access_key

  white_list :stack_id,
             :app_id,
             :branch_name,
             :aws_access_key_id

  url "http://docs.aws.amazon.com/opsworks/latest/APIReference/API_CreateDeployment.html"

  def receive_event
    create_deployment if branch_name == required_config_value('branch_name')
  end

  def create_deployment
    ops_works_client.create_deployment stack_id: required_config_value('stack_id'),
                                       app_id:   required_config_value('app_id'),
                                       command:  { name: 'deploy' }
  end

  def ops_works_client
    AWS::OpsWorks::Client.new access_key_id:     required_config_value('aws_access_key_id'),
                              secret_access_key: required_config_value('aws_secret_access_key')
  end

end
