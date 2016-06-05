class Service::AutoDeploy < Service::HttpPost
  password :github_token
  string   :environments
  boolean  :deploy_on_status
  string   :github_api_url

  white_list :environments, :deploy_on_status, :contexts, :github_api_url

  default_events :push, :status

  self.title = "GitHub Auto-Deployment"
  url 'http://www.atmos.org/github-services/auto-deployment/'
  logo_url 'https://camo.githubusercontent.com/edbc46e94fd4e9724da99bdd8da5d18e82f7b737/687474703a2f2f7777772e746f756368696e737069726174696f6e2e636f6d2f6173736574732f6865726f6b752d6c6f676f2d61663863386230333462346261343433613632376232393035666337316138362e706e67'

  maintained_by :github => 'atmos', :twitter => '@atmos'

  supported_by :web => 'https://github.com/contact',
    :email => 'support@github.com',
    :twitter => '@atmos'

  def github_repo_path
    if payload['repository'] && payload['repository']['full_name']
      payload['repository']['full_name']
    else
      [ payload['repository']['owner']['name'],
        payload['repository']['name'] ].join('/')
    end
  end

  def environment_names
    @environment_names ||= required_config_value("environments").split(',').map { |e| e.strip }
  end

  def payload_ref
    payload['ref'].to_s[/refs\/heads\/(.*)/, 1]
  end

  def sha
    if payload['after']
      payload['after'][0..7]
    else
      payload['sha'][0..7]
    end
  end

  def pusher_name
    if payload['pusher']
      payload['pusher']['name']
    else
      payload['commit']['committer']['login']
    end
  end

  def default_branch
    payload['repository']['default_branch']
  end

  def default_branch?
    payload_ref == default_branch
  end

  def deploy_on_push?
    !deploy_on_status?
  end

  def deploy_on_status?
    config_boolean_true?('deploy_on_status')
  end

  def version_string
    payload_ref == sha ? sha : "#{payload_ref}@#{sha}"
  end

  def receive_event
    http.ssl[:verify] = true

    case event.to_sym
    when :push
      github_user_access?
      github_repo_deployment_access?
      deploy_from_push_payload if deploy_on_push?
    when :status
      github_user_access?
      github_repo_deployment_access?
      deploy_from_status_payload if deploy_on_status?
    else
      raise_config_error_with_message(:no_event_handler)
    end
  end

  def push_deployment_description
    "Auto-Deployed on push by GitHub Services@#{Service.current_sha[0..7]} for #{pusher_name} - #{version_string}"
  end

  def status_deployment_description
    "Auto-Deployed on status by GitHub Services@#{Service.current_sha[0..7]} for #{pusher_name} - #{default_branch}@#{sha}"
  end

  def deploy_from_push_payload
    return unless default_branch?

    environment_names.each do |environment_name|
      deployment_options = {
        "ref"               => sha,
        "payload"           => last_deployment_payload_for(environment_name),
        "environment"       => environment_name,
        "description"       => push_deployment_description,
        "required_contexts" => [ ]
      }
      create_deployment_for_options(deployment_options)
    end
  end

  def status_payload_contains_default_branch?
    payload['branches'].any? { |branch| branch['name'] == default_branch }
  end

  def deploy_from_status_payload
    return unless payload['state'] == 'success'
    if status_payload_contains_default_branch?
      environment_names.each do |environment_name|
        deployment_options = {
          "ref"               => sha,
          "payload"           => last_deployment_payload_for(environment_name),
          "environment"       => environment_name,
          "description"       => status_deployment_description,
          "required_contexts" => [ ]
        }
        create_deployment_for_options(deployment_options)
      end
    end
  end

  def api_url
    if config_value("github_api_url").empty?
      "https://api.github.com"
    else
      config_value("github_api_url").chomp("/")
    end
  end

  def create_deployment_for_options(options)
    deployment_path = "/repos/#{github_repo_path}/deployments"
    response = http_post "#{api_url}#{deployment_path}" do |req|
      req.headers.merge!(default_github_headers)
      req.body = JSON.dump(options)
    end
    raise_config_error_with_message(:no_github_deployment_access) unless response.success?
  end

  def last_deployment_payload_for(environment)
    response = github_get("/repos/#{github_repo_path}/deployments")
    unless response.success?
      raise_config_error_with_message(:no_github_repo_deployment_access)
    end
    deployment = JSON.parse(response.body).find do |element|
      element['environment'] == environment
    end
    deployment ? deployment['payload'] : { }
  end

  def github_user_access?
    response = github_get("/user")
    unless response.success?
      raise_config_error_with_message(:no_github_user_access)
    end
  end

  def github_repo_deployment_access?
    response = github_get("/repos/#{github_repo_path}/deployments")
    unless response.success?
      raise_config_error_with_message(:no_github_repo_deployment_access)
    end
  end

  def github_get(path)
    http_get "#{api_url}#{path}" do |req|
      req.headers.merge!(default_github_headers)
    end
  end

  def default_github_headers
    {
      'Accept'        => "application/vnd.github.cannonball-preview+json",
      'User-Agent'    => "Operation: California Auto-Deploy",
      'Content-Type'  => "application/json",
      'Authorization' => "token #{required_config_value('github_token')}"
    }
  end

  def raise_config_error_with_message(sym)
    raise_config_error(error_messages[sym])
  end

  def error_messages
    @default_error_messages ||= {
      :no_event_handler =>
        "The #{event} event is currently unsupported.",
      :no_github_user_access =>
        "Unable to access GitHub with the provided token.",
      :no_github_repo_deployment_access =>
        "Unable to access the #{github_repo_path} repository's deployments on GitHub with the provided token.",
      :no_github_repo_deployment_status_access =>
        "Unable to update the deployment status on GitHub with the provided token."
    }
  end
end
