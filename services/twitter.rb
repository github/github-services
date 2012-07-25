class Service::Twitter < Service
  string  :token, :secret
  boolean :digest

  def receive_push
    return unless payload['commits']

    statuses   = []
    repository = payload['repository']['name']

    if data['digest'] == '1'
      commit = payload['commits'][-1]
      author = commit['author'] || {}
      tiny_url = shorten_url("#{payload['repository']['url']}/commits/#{ref_name}")
      status = "[#{repository}] #{tiny_url} #{author['name']} - #{payload['commits'].length} commits"
      status.length >= 140 ? statuses << status[0..136] + '...' : statuses << status
    else
      payload['commits'].each do |commit|
        author = commit['author'] || {}
        tiny_url = shorten_url(commit['url'])
        status = "[#{repository}] #{tiny_url} #{author['name']} - #{commit['message']}"
        status.length >= 140 ? statuses << status[0..136] + '...' : statuses << status
      end
    end

    statuses.each do |status|
      post(status)
    end
  end

  def post(status)
    params = { 'status' => status, 'source' => 'github' }

    access_token = ::OAuth::AccessToken.new(consumer, data['token'], data['secret'])
    res = consumer.request(:post, "/1/statuses/update.json",
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
    JSON.parse(res.body)['error']
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
