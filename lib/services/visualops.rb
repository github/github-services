class Service::VisualOps < Service
  string :username, :app_list
  password :consumer_token

  white_list :username, :app_list

  default_events :push

  url "http://www.visualops.io"

  maintained_by :github => "gnawux", 
      :twitter => "@gnawux" 

  supported_by :email => 'support@visualops.io'

  def receive_push
    return unless update_states?

    # Confirm all required config is present
    assert_required_credentials :push

    # Update State
    app = push_list(app_list)
    if not app.empty?
      update_apps(app)
    end
  end

  private

  def update_states?
    return false if payload['commits'].size == 0
    true
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

  def assert_required_credentials(event)
    if (consumer_token.empty? || username.empty?)
      raise_config_error "You need a user ID and an authorization Token. See tips below."
    end
  end

  def update_apps(apps)
    http_post "https://api.visualops.io/v1/apps" do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        :user  => username,
        :app   => apps,
        :token => consumer_token,
        :src   => branch_url
        }.to_json
    end
  end

  def consumer_token
    data['consumer_token'].to_s
  end

  def username
    data['username'].to_s
  end
end
