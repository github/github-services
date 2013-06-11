class Service::Twitter < Service
  string  :token, :secret
  boolean :digest, :short_format

  def receive_push
    return unless payload['commits']

    statuses   = []
    repository = payload['repository']['name']

    if data['digest'] == '1'
      commit = payload['commits'][-1]
      author = commit['author'] || {}
      url = "#{payload['repository']['url']}/commits/#{ref_name}"
      status = "[#{repository}] #{url} #{author['name']} - #{payload['commits'].length} commits"
      status = if data['short_format'] == '1'
        "#{url} - #{payload['commits'].length} commits"
      else
        "[#{repository}] #{url} #{author['name']} - #{payload['commits'].length} commits"
      end
      length = status.length - url.length + 21 # The URL is going to be shortened by twitter. It's length will be at most 21 chars (HTTPS).
      # How many chars of the status can we actually use?
      # We can use 140 chars, have to reserve 3 chars for the railing dots (-3)
      # also 21 chars for the t.co-URL (-21) but can fit the whole URL into the tweet (+url.length)
      usable_chars = 140 - 3 - 21 + url.length
      length >= 140 ? statuses << status[0..(usable_chars-1)] + '...' : statuses << status
    else
      payload['commits'].each do |commit|
        author = commit['author'] || {}
        url = commit['url']
        status = "[#{repository}] #{url} #{author['name']} - #{commit['message']}"
        status = if data['short_format'] == '1'
          "#{url} #{commit['message']}"
        else
          "[#{repository}] #{url} #{author['name']} - #{commit['message']}"
        end
        length = status.length - url.length + 21 # The URL is going to be shortened by twitter. It's length will be at most 21 chars (HTTPS).
        # How many chars of the status can we actually use?
        # We can use 140 chars, have to reserve 3 chars for the railing dots (-3)
        # also 21 chars for the t.co-URL (-21) but can fit the whole URL into the tweet (+url.length)
        usable_chars = 140 - 3 - 21 + url.length
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
                                        {:site => "http://api.twitter.com"})
  end
end
