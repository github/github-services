class Service::VisualOps < Service
  string :app_id, :user_id, :watch_branch
  password :consumer_token

  white_list :app_id, :user_id, :watch_branch

  default_events :push

  url "http://www.visualops.io"

  maintained_by :github => "gnawux", :twitter => "@gnawux" 

  supported_by :email => 'support@visualops.io'

  def receive_push
    return unless update_states?

    # Confirm all required config is present
    assert_required_credentials :push

    # Update State
    update_state :push
  end

  private

  def update_states?
    return false if payload['commits'].size == 0
    return false if branch_name != data['watch_branch']
    true
  end

  def assert_required_credentials(event)
    if consumer_token.empty?
      raise_config_error "You need an authorization Token. See tips below."
    end
  end

  def update_state(event, name, description)
    http.url_prefix = "https://api.visualops.io/v1/apps"
    http_post data['app_id'],
      :user => data['user_id'],
      :token => consumer_token
  end

  def consumer_token
    data['consumer_token'].to_s
  end
end
