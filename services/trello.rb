class Service::Trello < Service
  string :list_id, :ignore_regex
  boolean  :master_only
  password :consumer_token

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

  def create_cards
    http.url_prefix = "https://api.trello.com/1"

    payload['commits'].each do |commit|
      next if ignore_commit? commit

      http_post "cards",
        :name => name_for_commit(commit),
        :desc => desc_for_commit(commit),
        :idList => list_id,
        :key => application_key,
        :token => consumer_token
    end
  end

  def ignore_commit? commit
    ignore_regex && ignore_regex.match(commit['message'])
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

  def ignore_regex
    @_memoized_ignore_regexp ||= if data['ignore_regex'].to_s.blank?
      nil
    else
      Regexp.new(data['ignore_regex'].to_s)
    end
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
end
