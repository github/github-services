require 'aws/ops_works'

class Service::AwsOpsWorks < Service::HttpPost
  self.title = 'AWS OpsWorks'

  string     :app_id,               # see AppId at http://docs.aws.amazon.com/opsworks/latest/APIReference/API_App.html
             :stack_id,             # see StackId at http://docs.aws.amazon.com/opsworks/latest/APIReference/API_Stack.html
             :branch_name,          # see Revision at http://docs.aws.amazon.com/opsworks/latest/APIReference/API_Source.html
             :endpoint_region,      # see AWS Opsworks Stacks at http://docs.aws.amazon.com/general/latest/gr/rande.html#opsworks_region
             :github_api_url,       # The GitHub API endpoint to post DeploymentStatus callbacks to
             :aws_access_key_id     # see AWSAccessKeyID at http://docs.aws.amazon.com/opsworks/latest/APIReference/CommonParameters.html
  password   :aws_secret_access_key, :github_token

  white_list :app_id,
             :stack_id,
             :branch_name,
             :endpoint_region,
             :github_api_url,
             :aws_access_key_id

  default_events :push, :deployment
  url "http://docs.aws.amazon.com/opsworks/latest/APIReference/API_CreateDeployment.html"

  def app_id
    environment_app_id || required_config_value('app_id')
  end

  def stack_id
    environment_stack_id || required_config_value('stack_id')
  end

  def deployment_payload
    payload['deployment']
  end

  def deployment_command
    (deployment_payload && deployment_payload['task']) || 'deploy'
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
    deployment_payload && deployment_payload['payload'] &&
      deployment_payload['payload']['config'] &&
      deployment_payload['payload']['config']['opsworks']
  end

  def environment
    deployment_payload['environment']
  end

  def receive_event
    http.ssl[:verify] = true

    case event.to_s
    when 'deployment'
      update_app_revision(deployment_ref_name)
      app_deployment = create_deployment
      update_deployment_statuses(app_deployment)
      app_deployment
    when 'push'
      if branch_name == required_config_value('branch_name')
        create_deployment
      end
    else
      raise_config_error("The #{event} event is currently unsupported.")
    end
  end

  def update_deployment_statuses(app_deployment)
    return unless config_value('github_token') && !config_value('github_token').empty?

    deployment_id = app_deployment['deployment_id']

    deployment_status_options = {
      "state"       => "success",
      "target_url"  => aws_opsworks_output_url,
      "description" => "Deployment #{payload['deployment']['id']} Accepted by Amazon. (github-services@#{Service.current_sha[0..7]})"
    }

    deployment_path = "/repos/#{github_repo_path}/deployments/#{payload['deployment']['id']}/statuses"
    response = http_post "#{github_api_url}#{deployment_path}" do |req|
      req.headers.merge!(default_github_headers)
      req.body = JSON.dump(deployment_status_options)
    end
    raise_config_error("Unable to post deployment statuses back to the GitHub API.") unless response.success?
  end

  def aws_opsworks_output_url
    "https://console.aws.amazon.com/opsworks/home?#/stack/#{stack_id}/deployments"
  end

  def default_github_headers
    {
      'Accept'        => "application/vnd.github.cannonball-preview+json",
      'User-Agent'    => "Operation: California",
      'Content-Type'  => "application/json",
      'Authorization' => "token #{required_config_value('github_token')}"
    }
  end

  def github_repo_path
    payload['repository']['full_name']
  end

  def configured_branch_name
    required_config_value('branch_name')
  end

  def deployment_ref_name
    payload['deployment']['ref']
  end

  def update_app_revision(revision_name)
    app_source = { revision: revision_name }
    if config_value('github_token') && !config_value('github_token').empty?
      app_source = {
        url: "#{github_api_url}/repos/#{github_repo_path}/zipball/#{revision_name}",
        type: "archive",
        username: required_config_value("github_token"),
        password: "x-oauth-basic",
        revision: revision_name
      }
    end
    ops_works_client.update_app app_id: app_id, app_source: app_source
  end

  def create_deployment
    ops_works_client.create_deployment stack_id: stack_id, app_id: app_id,
                                       command:  { name: deployment_command }
  end

  def ops_works_client
    region = config_value('endpoint_region')
    # The AWS library requires you pass `nil`, and not an empty string, if you
    # want to connect to a legitimate default AWS host name.
    region = nil if region.empty?
    AWS::OpsWorks::Client.new access_key_id:     required_config_value('aws_access_key_id'),
                              secret_access_key: required_config_value('aws_secret_access_key'),
                              region:            region
  end

  def github_api_url
    if config_value("github_api_url").empty?
      "https://api.github.com"
    else
      config_value("github_api_url")
    end
  end
end
