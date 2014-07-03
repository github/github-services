require 'base64'

class Service::HerokuBeta < Service::HttpPost
  string :name
  # boolean  :basic_auto_deploy, :status_driven_auto_deploy
  password :heroku_token, :github_token

  white_list :name

  default_events :deployment

  url 'https://heroku.com'
  logo_url 'https://camo.githubusercontent.com/edbc46e94fd4e9724da99bdd8da5d18e82f7b737/687474703a2f2f7777772e746f756368696e737069726174696f6e2e636f6d2f6173736574732f6865726f6b752d6c6f676f2d61663863386230333462346261343433613632376232393035666337316138362e706e67'

  maintained_by :github => 'atmos', :twitter => '@atmos'

  supported_by :web => 'https://github.com/contact',
    :email => 'support@github.com',
    :twitter => '@atmos'

  def github_repo_path
    payload['repository']['full_name']
  end

  def environment
    payload['environment']
  end

  def ref
    payload['ref']
  end

  def sha
    payload['sha'][0..7]
  end

  def version_string
    ref == sha ? sha : "#{ref}@#{sha}"
  end

  def receive_event
    http.ssl[:verify] = true

    case event
    when :deployment
      heroku_app_access?
      github_user_access?
      github_repo_access?
      deploy
    when :status
      # create a deployment if the default branch is pushed to and commit
      # status is green
      raise_config_error_with_message(:no_event_handler)
    when :push
      # create a deployment if the default branch is pushed to(basic-auto-deploy)
      raise_config_error_with_message(:no_event_handler)
    else
      raise_config_error_with_message(:no_event_handler)
    end
  end

  def heroku_application_name
    required_config_value('name')
  end

  def heroku_headers
    {
      'Accept'        => 'application/vnd.heroku+json; version=3',
      'Content-Type'  => "application/json",
      "Authorization" => Base64.encode64(":#{required_config_value('heroku_token')}").strip
    }
  end

  def deploy
    response = http_post "https://api.heroku.com/apps/#{heroku_application_name}/builds" do |req|
      req.headers.merge!(heroku_headers)
      req.body = JSON.dump({:source_blob => {:url => repo_archive_link, :version => version_string}})
    end
    raise_config_error_with_message(:no_heroku_app_build_access) unless response.success?

    build_id = JSON.parse(response.body)['id']
    deployment_status_options = {
      "state"       => "pending",
      "target_url"  => heroku_build_output_url(build_id),
      "description" => "Created by GitHub Services@#{Service.current_sha[0..7]}"
    }

    deployment_path = "/repos/#{github_repo_path}/deployments/#{payload['id']}/statuses"
    response = http_post "https://api.github.com#{deployment_path}" do |req|
      req.headers.merge!(default_github_headers)
      req.body = JSON.dump(deployment_status_options)
    end
    raise_config_error_with_message(:no_github_deployment_access) unless response.success?
  end

  def heroku_build_output_url(id)
    "https://api.heroku.com/apps/#{heroku_application_name}/builds/#{id}/result"
  end

  def heroku_app_access?
    response = http_get "https://api.heroku.com/apps/#{heroku_application_name}" do |req|
      req.headers.merge!(heroku_headers)
    end
    unless response.success?
      raise_config_error_with_message(:no_heroku_app_access)
    end
  end

  def github_user_access?
    response = github_get("/user")
    unless response.success?
      raise_config_error_with_message(:no_github_user_access)
    end
  end

  def github_repo_access?
    response = github_get("/repos/#{github_repo_path}")
    unless response.success?
      raise_config_error_with_message(:no_github_repo_access)
    end
  end

  def repo_archive_link
    response = github_get("/repos/#{github_repo_path}/tarball/#{sha}")
    unless response.status == 302
      raise_config_error_with_message(:no_github_archive_link)
    end
    response.headers['Location']
  end

  def github_get(path)
    http_get "https://api.github.com#{path}" do |req|
      req.headers.merge!(default_github_headers)
    end
  end

  def default_github_headers
    {
      'Accept'        => "application/vnd.github.cannonball-preview+json",
      'User-Agent'    => "Operation: California",
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
      :no_github_archive_link =>
        "Unable to generate an archive link for #{github_repo_path} on GitHub with the provided token.",
      :no_github_repo_access =>
        "Unable to access the #{github_repo_path} repository on GitHub with the provided token.",
      :no_github_user_access =>
        "Unable to access GitHub with the provided token.",
      :no_github_deployment_access =>
        "Unable to update the deployment status on GitHub with the provided token.",
      :no_heroku_app_access =>
        "Unable to access #{heroku_application_name} on heroku with the provided token.",
      :no_heroku_app_build_access =>
        "Unable to create a build for #{heroku_application_name} on heroku with the provided token."
    }
  end
end
