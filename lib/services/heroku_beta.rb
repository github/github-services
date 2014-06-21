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

  # A runtime configured endpoint that receives these payloads
  # This should not be user configurable.
  def heroku_builder_url
    ENV['HEROKU_BUILDER_URL'] || 'https://169.254.1.1/events'
  end

  def full_name
    payload['repository']['full_name']
  end

  def receive_event
    # verify access to app name with heroku_token
    verify_heroku
    # verify auth plus required scopes (repo, gist)
    verify_github

    deliver heroku_builder_url
  end

  def verify_heroku
    name         = required_config_value('name')
    heroku_token = required_config_value('heroku_token')

    response = http_get "https://api.heroku.com/apps/#{name}" do |req|
      req.headers['Accept']        = 'application/vnd.heroku+json; version=3'
      req.headers['Content-Type']  = "application/json",
      req.headers["Authorization"] = Base64.encode64(":#{heroku_token}")
    end
    unless response.success?
      raise_config_error("Unable to access #{name} on heroku with the provided token.")
    end
  end

  def verify_github
    github_token = required_config_value('github_token')

    response = http_get "https://api.github.com/user" do |req|
      req.headers['Content-Type']  = "application/json",
      req.headers["Authorization"] = "token #{github_token}"
    end
    unless response.success?
      raise_config_error("Unable to access GitHub with the provided token.")
    end

    response = http_get "https://api.github.com/repos/#{full_name}" do |req|
      req.headers['Content-Type']  = "application/json",
      req.headers["Authorization"] = "token #{github_token}"
    end
    unless response.success?
      raise_config_error("Unable to access the #{full_name} repository on GitHub with the provided token.")
    end

    scopes = response.headers['X-OAuth-Scopes'].split(",").map(&:strip)
    unless scopes.include?("gist")
      raise_config_error("No gist scope for your GitHub token, check the scopes of your personal access token.")
    end
  end
end
