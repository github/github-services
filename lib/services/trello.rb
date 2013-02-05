class Service::Trello < Service
  string :push_list_id, :pull_request_list_id, :ignore_regex
  boolean  :master_only
  password :consumer_token

  default_events :push, :pull_request

  def receive_pull_request
    return unless opened?

    assert_required_credentials :pull_request
    
    create_card :pull_request, name_for_pull(pull), desc_for_pull(pull)
  end

  def name_for_pull(pull)
    pull.title
  end

  def desc_for_pull(pull)
    "Author: %s\n\n%s\n\nDescription: %s" % [
      pull.user.login,
      pull.html_url,
      pull.body || '[no description]'
    ]
  end

  def receive_push
    return unless create_cards?

    # Confirm all required config is present
    assert_required_credentials :push

    # Create the card
    create_cards :push
  end

  private

  def create_cards?
    return false if payload['commits'].size == 0
    return false if data['master_only'].to_i == 1 && branch_name != 'master'
    true
  end

  def assert_required_credentials(event)
    if consumer_token.empty?
      raise_config_error "You need an authorization Token. See tips below."
    end
    if list_id(event).empty?
      raise_config_error "You need to enter a list identifiter. See tips below."
    end
  end

  def create_card(event, name, description)
    http.url_prefix = "https://api.trello.com/1"
    http_post "cards",
      :name => name,
      :desc => description,
      :idList => list_id(event),
      :key => application_key,
      :token => consumer_token
  end
    

  def create_cards(event)
    payload['commits'].each do |commit|
      next if ignore_commit? commit
      create_card event, name_for_commit(commit), desc_for_commit(commit)
    end
  end

  def ignore_commit? commit
    ignore_regex && ignore_regex.match(commit['message'])
  end

  def truncate_message(message)
    message.length > message_max_length ? message[0...message_max_length] + "..." : message
  end

  def name_for_commit commit
    truncate_message commit['message']
  end

  def desc_for_commit commit
    author = commit['author'] || {}

    "Author: %s\n\n%s\n\nRepo: %s\n\nBranch: %s\n\nCommit Message: %s" % [
      author['name'] || '[unknown]',
      commit['url'],
      repository,
      branch_name,
      commit['message'] || '[no description]'
    ]
  end

  def consumer_token
    data['consumer_token'].to_s
  end

  def list_id(event)
    list = data["#{event}_list_id"]
    
    # this should make the old `list_id`, which was implicitly for push,
    # backwards-compatible
    list ||= data["list_id"] if event == :push
    
    list.to_s
  end

  def ignore_regex
    @_memoized_ignore_regexp ||= if data['ignore_regex'].to_s.blank?
      nil
    else
      Regexp.new(data['ignore_regex'].to_s)
    end
  end

  def application_key
    "db1e35883bfe8f8da1725a0d7d032a9c"
  end

  def repository
    payload['repository']['name']
  end

  def message_max_length
    80
  end
end
