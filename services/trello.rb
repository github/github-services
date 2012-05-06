class Service::Trello < Service
  string :consumer_token, :list_id

  def receive_push
    return if payload['commits'].size == 0

    # Confirm all required config is present
    assert_required_credentials

    # Create the card
    create_card
  end

  private

  def create_card
    http.url_prefix = "https://api.trello.com/1"

    payload['commits'].each do |commit|
      http_post "cards",
        :name => name_for_commit(commit),
        :desc => desc_for_commit(commit),
        :idList => list_id,
        :key => application_key,
        :token => consumer_token
    end
  end

  def name_for_commit commit
    commit['message'].length > message_max_length ? \
      commit['message'][0...message_max_length] + '...' : \
      commit['message']
  end

  def desc_for_commit commit
    author = commit['author'] || {}
    
    "Author: %s\n\n%s\n\nRepo: %s\n\nCommit Message: %s" % [
      author['name'] || '[unknown]',
      commit['url'],
      repository,
      commit['message'] || '[no description]'
    ]
  end

  def consumer_token
    data['consumer_token'].to_s
  end

  def list_id
    data['list_id'].to_s
  end

  def application_key
    "74666606852cabea363165a7cd5b7dc9"
  end

  def repository
    payload['repository']['name']
  end

  def message_max_length
    80
  end

  def assert_required_credentials
    if consumer_token.empty?
      raise_config_error "You need an authorization Token. See tips below."
    end
    if list_id.empty?
      raise_config_error "You need to enter a list identifiter. See tips below."
    end
  end
end
