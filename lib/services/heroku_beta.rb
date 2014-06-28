class Service::HerokuBeta < Service::HttpPost
  string :name
  password :heroku_token, :github_token

  white_list :name

  default_events :deployment

  url 'https://heroku.com'
  logo_url 'https://camo.githubusercontent.com/edbc46e94fd4e9724da99bdd8da5d18e82f7b737/687474703a2f2f7777772e746f756368696e737069726174696f6e2e636f6d2f6173736574732f6865726f6b752d6c6f676f2d61663863386230333462346261343433613632376232393035666337316138362e706e67'

  maintained_by :github => 'atmos', :twitter => '@atmos'

  supported_by :web => 'https://github.com/contact',
    :email => 'support@github.com',
    :twitter => '@atmos'

  def full_name
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
    verify_heroku_app_access
    verify_github_user_and_repo_access
    deploy
  end

  def heroku_application_name
    required_config_value('name')
  end

  def deploy
    response = http_post "https://api.heroku.com/apps/#{heroku_application_name}/builds" do |req|
      req.headers.merge!(heroku_headers)
      req.body = JSON.dump({:source_blob => {:url => repo_archive_link, :version => version_string}})
    end
    unless response.success?
      raise_config_error_with_message(:no_heroku_app_build_access)
    end
  end

  def heroku_headers
    {
      'Accept'        => 'application/vnd.heroku+json; version=3',
      'Content-Type'  => "application/json",
      "Authorization" => Base64.encode64(":#{required_config_value('heroku_token')}")
    }
  end

  def verify_heroku_app_access
    response = http_get "https://api.heroku.com/apps/#{heroku_application_name}" do |req|
      req.headers.merge!(heroku_headers)
    end
    unless response.success?
      raise_config_error_with_message(:no_heroku_app_access)
    end
  end

  def verify_github_user_and_repo_access
    ensure_github_get("/user") do
      raise_config_error_with_message(:no_github_user_access)
    end

    response = ensure_github_get("/repos/#{full_name}") do
      raise_config_error_with_message(:no_github_repo_access)
    end
  end

  def repo_archive_link
    response = ensure_github_get("/repos/#{full_name}/tarball/#{sha}") do
      raise_config_error_with_message(:no_github_archive_link)
    end
    response.headers['Location']
  end

  def ensure_github_get(path, &block)
    response = github_get(path)
    unless response.success?
      yield
    end
    response
  end

  def github_get(path)
    http_get "https://api.github.com#{path}" do |req|
      req.headers['Content-Type']  = "application/json",
      req.headers["Authorization"] = "token #{required_config_value('github_token')}"
    end
  end

  def raise_config_error_with_message(sym)
    raise_config_error error_messages[sym]
  end

  def error_messages
    @default_error_messages ||= {
      :no_github_archive_link =>
        "Unable to generate an archive link for #{full_name} on GitHub with the provided token.",
      :no_github_repo_access =>
        "Unable to access the #{full_name} repository on GitHub with the provided token.",
      :no_github_user_access =>
        "Unable to access GitHub with the provided token.",
      :no_heroku_app_access =>
        "Unable to access #{heroku_application_name} on heroku with the provided token.",
      :no_heroku_app_build_access =>
        "Unable to create a build for #{heroku_application_name} on heroku with the provided token."
    }
  end
end
