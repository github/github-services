class Service::Trello < Service
  string :list_id, :ignore_regex
  boolean  :master_only
  password :consumer_token

  default_events :push, :pull_request

  def receive_pull_request
    return unless opened?
    
    create_card truncate_message(pull.title), 
                "%s : %s " % [pull.summary_message, pull.summary_url]
  end

  def receive_push
    return unless create_cards?

    # Confirm all required config is present
    assert_required_credentials

    # Create the card
    create_cards
  end

  private

  def create_cards?
    return false if payload['commits'].size == 0
    return false if data['master_only'].to_i == 1 && branch_name != 'master'
    true
  end

  def assert_required_credentials
    if consumer_token.empty?
      raise_config_error "You need an authorization Token. See tips below."
    end
    if list_id.empty?
      raise_config_error "You need to enter a list identifiter. See tips below."
    end
  end

  def create_card(name, description)
    http.url_prefix = "https://api.trello.com/1"
    http_post "cards",
      :name => name,
      :desc => description,
      :idList => list_id,
      :key => application_key,
      :token => consumer_token
  end
    

  def create_cards
    payload['commits'].each do |commit|
      next if ignore_commit? commit
      create_card name_for_commit(commit), desc_for_commit(commit)
    end
  end

  def ignore_commit? commit
    ignore_regex && ignore_regex.match(commit['message'])
  end

  def truncate_message(message)
    message.length > message_max_length ? message[0..message_max_length] + "..." : message
  end

  def name_for_commit commit
    truncate_message commit['message']
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
