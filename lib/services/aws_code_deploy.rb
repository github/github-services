require 'aws-sdk-core'

class Service::AwsCodeDeploy < Service::HttpPost
  self.title = 'AWS CodeDeploy'

  string     :application_name, :deployment_group,
             :aws_access_key_id, :aws_region, :github_api_url

  password   :aws_secret_access_key, :github_token

  white_list :application_name,
             :deployment_group,
             :github_api_url,
             :aws_access_key_id,
             :aws_region

  default_events :deployment
  url "http://docs.aws.amazon.com/codedeploy/latest/APIReference/"

  def environment
    payload['deployment']['environment']
  end

  def application_name
    environment_application_name || required_config_value('application_name')
  end

  def environment_application_name
    codedeploy_payload_environment('application_name')
  end

  def codedeploy_payload_environment(key)
    codedeploy_payload &&
      codedeploy_payload[environment] &&
      codedeploy_payload[environment][key]
  end

  def codedeploy_payload
    payload['deployment']['payload'] &&
      payload['deployment']['payload']['config'] &&
      payload['deployment']['payload']['config']['codedeploy']
  end

  def receive_event
    http.ssl[:verify] = true

    case event.to_s
    when 'deployment'
      deployment = create_deployment
      update_deployment_statuses(deployment)
      deployment
    else
      raise_config_error("The #{event} event is currently unsupported.")
    end
  end

  def create_deployment
    options = {
      :revision => {
        :git_hub_location => {
          :commit_id  => payload['deployment']["sha"],
          :repository => github_repo_path,
        },
        :revision_type => "GitHub"
      },

      :application_name      => application_name,
      :deployment_group_name => environment
    }
    code_deploy_client.create_deployment(options)
  end

  def update_deployment_statuses(deployment)
    return unless config_value('github_token') && !config_value('github_token').empty?

    deployment_id = deployment['deployment_id']

    deployment_status_options = {
      "state"       => "success",
      "target_url"  => aws_code_deploy_client_url,
      "description" => "Deployment #{payload['deployment']['id']} Accepted by Amazon. (github-services@#{Service.current_sha[0..7]})"
    }

    deployment_path = "/repos/#{github_repo_path}/deployments/#{payload['deployment']['id']}/statuses"
    response = http_post "#{github_api_url}#{deployment_path}" do |req|
      req.headers.merge!(default_github_headers)
      req.body = JSON.dump(deployment_status_options)
    end
    raise_config_error("Unable to post deployment statuses back to the GitHub API.") unless response.success?
  end

  def aws_code_deploy_client_url
    "https://console.aws.amazon.com/codedeploy/home?region=#{custom_aws_region}#/deployments"
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

  def code_deploy_aws_region
    (codedeploy_payload &&
     codedeploy_payload["aws"] &&
     codedeploy_payload["aws"]["region"])
  end

  def custom_aws_region
    return code_deploy_aws_region if code_deploy_aws_region
    if config_value('aws_region').empty?
      'us-east-1'
    else
      config_value('aws_region')
    end
  end

  def stubbed_responses?
    !!ENV['CODE_DEPLOY_STUB_RESPONSES']
  end

  def aws_config
    {
      :region            => custom_aws_region,
      :logger            => stubbed_responses? ? nil : Logger.new(STDOUT),
      :access_key_id     => required_config_value("aws_access_key_id"),
      :secret_access_key => required_config_value("aws_secret_access_key"),
      :stub_responses    => stubbed_responses?
    }
  end

  def code_deploy_client
    @code_deploy_client ||= ::Aws::CodeDeploy::Client.new(aws_config)
  end

  def github_api_url
    if config_value("github_api_url").empty?
      "https://api.github.com"
    else
      config_value("github_api_url")
    end
  end
end
