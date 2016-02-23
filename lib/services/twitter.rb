class Service::Twitter < Service
  password  :token, :secret
  string :filter_branch
  boolean :digest, :short_format
  TWITTER_SHORT_URL_LENGTH_HTTPS = 23

  white_list :filter_branch

  def receive_push
    return unless payload['commits']

    commit_branch = (payload['ref'] || '').split('/').last || ''
    filter_branch = data['filter_branch'].to_s

    # If filtering by branch then don't make a post
    if (filter_branch.length > 0) && (commit_branch.index(filter_branch) == nil)
      return false
    end

    statuses   = []
    repository = payload['repository']['name']

    if config_boolean_true?('digest')
      commit = payload['commits'][-1]
      author = commit['author'] || {}
      url = "#{payload['repository']['url']}/commits/#{ref_name}"
      status = "[#{repository}] #{url} #{author['name']} - #{payload['commits'].length} commits"
      status = if short_format?
        "#{url} - #{payload['commits'].length} commits"
      else
        "[#{repository}] #{url} #{author['name']} - #{payload['commits'].length} commits"
      end
      length = status.length - url.length + TWITTER_SHORT_URL_LENGTH_HTTPS # The URL is going to be shortened by twitter. It's length will be at most 23 chars (HTTPS).
      # How many chars of the status can we actually use?
      # We can use 140 chars, have to reserve 3 chars for the railing dots (-3)
      # also 23 chars for the t.co-URL (-23) but can fit the whole URL into the tweet (+url.length)
      usable_chars = 140 - 3 - TWITTER_SHORT_URL_LENGTH_HTTPS + url.length
      length >= 140 ? statuses << status[0..(usable_chars-1)] + '...' : statuses << status
    else
      payload['commits'].each do |commit|
        author = commit['author'] || {}
        url = commit['url']
        message = commit['message']
        # Strip out leading @s so that github @ mentions don't become twitter @ mentions
        # since there's zero reason to believe IDs on one side match IDs on the other
        message.gsub!(/\B[@＠][[:word:]]/) do |word|
          "@\u200b#{word[1..word.length]}"
        end
        status = if short_format?
          "#{url} #{message}"
        else
          "[#{repository}] #{url} #{author['name']} - #{message}"
        end
        # Twitter barfs on asterisks so replace them with a slightly different unicode one.
        status.gsub!("*", "﹡")
        # The URL is going to be shortened by twitter. It's length will be at most 23 chars (HTTPS).
        length = status.length - url.length + TWITTER_SHORT_URL_LENGTH_HTTPS
        # How many chars of the status can we actually use?
        # We can use 140 chars, have to reserve 3 chars for the railing dots (-3)
        # also 23 chars for the t.co-URL (-23) but can fit the whole URL into the tweet (+url.length)
        usable_chars = 140 - 3 - TWITTER_SHORT_URL_LENGTH_HTTPS + url.length
        length >= 140 ? statuses << status[0..(usable_chars-1)] + '...' : statuses << status
      end
    end

    statuses.each do |status|
      post(status)
    end
  end

  def post(status)
    params = { 'status' => status }

    access_token = ::OAuth::AccessToken.new(consumer, data['token'], data['secret'])
    res = consumer.request(:post, "/1.1/statuses/update.json",
      access_token, { :scheme => :query_string }, params)
    if res.code !~ /^2\d\d/
      raise_response_error(res)
    end
  end

  def raise_response_error(res)
    error = "Received HTTP #{res.code}"
    if msg = response_error_message(res)
      error << ": "
      error << msg
    end

    raise_config_error(error)
  end

  def response_error_message(res)
    JSON.parse(res.body)['errors'].map { |error| error['message'] }.join('; ')
  rescue
  end

  def consumer_key
    secrets['twitter']['key']
  end

  def consumer_secret
    secrets['twitter']['secret']
  end

  def consumer
    @consumer ||= ::OAuth::Consumer.new(consumer_key, consumer_secret,
                                        {:site => "https://api.twitter.com"})
  end

  def short_format?
    config_boolean_true?('short_format')
  end
end
