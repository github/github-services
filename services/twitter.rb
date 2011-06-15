class Service::Twitter < Service
  def receive_push
    statuses   = [ ]
    repository = payload['repository']['name']

    if data['digest'] == '1'
      commit = payload['commits'][-1]
      author = commit['author'] || {}
      tiny_url = shorten_url(payload['repository']['url'] + '/commits/' + payload['ref_name'])
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
    consumer.request(:post, "/1/statuses/update.json",
                     access_token, { :scheme => :query_string }, params)
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
