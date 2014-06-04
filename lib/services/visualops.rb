class Service::VisualOps < Service::HttpPost
  string :username, :app_list
  password :consumer_token

  white_list :username, :app_list

  default_events :push

  url "http://www.visualops.io"

  maintained_by :github => "gnawux", 
      :twitter => "@gnawux" 

  supported_by :email => 'support@visualops.io'

  def receive_event
    return unless update_states?

    # Confirm all required config is present
    assert_required_credentials

    # Update State
    app = push_list(app_list)
    if not app.empty?
      data.update('app_list' => app)
      deliver update_url, :content_type => 'application/json'
    end
  end

  private

  def update_states?
    payload['commits'].size != 0
  end

  def app_list
    data['app_list'].split(',').map do |ab_pair|
      (app, sep, bx) = ab_pair.strip.partition(":")
      branch = bx.empty? ? "master" : bx
      [app, branch]
    end
  end

  def push_list(apps)
    apps.keep_if{|x| x[1] == branch_name}.map{|x| x[0]}
  end

  def assert_required_credentials
    if (consumer_token.empty? || username.empty?)
      raise_config_error "You need a user ID and an authorization Token."
    end
  end

  def update_url
    "https://api.visualops.io:443/v1/github"
  end

  def consumer_token
    data['consumer_token'].to_s
  end

  def username
    data['username'].to_s
  end
end
