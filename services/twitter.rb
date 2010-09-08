class TwitterOAuth
  def initialize(token, secret)
    @token   = token
    @secret  = secret
    @secrets = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'secrets.yml'))
  end

  def consumer_key
    @secrets['twitter']['key']
  end

  def consumer_secret
    @secrets['twitter']['secret']
  end

  def consumer
    @consumer ||= ::OAuth::Consumer.new(consumer_key, consumer_secret,
                                        {:site => "http://api.twitter.com"})
  end

  def post(status)
    params = { 'status' => status, 'source' => 'github' }

    access_token = ::OAuth::AccessToken.new(consumer, @token, @secret)
    oauth_response = consumer.request(:post, "/1/statuses/update.json",
                                      access_token, { :scheme => :query_string }, params)
    case oauth_response
    when Net::HTTPSuccess
      JSON.parse(oauth_response.body)
    else
      nil
    end
  end
end

service :twitter do |data, payload|
  statuses   = [ ]
  repository = payload['repository']['name']

  if data['digest'] == '1'
    commit = payload['commits'][-1]
    tiny_url = shorten_url(payload['repository']['url'] + '/commits/' + payload['ref_name'])
    statuses << "[#{repository}] #{tiny_url} #{commit['author']['name']} - #{payload['commits'].length} commits"
  else
    payload['commits'].each do |commit|
      tiny_url = shorten_url(commit['url'])
      statuses << "[#{repository}] #{tiny_url} #{commit['author']['name']} - #{commit['message']}"
    end
  end

  twitter_oauth = TwitterOAuth.new(data['token'], data['secret'])
  statuses.each do |status|
    twitter_oauth.post(status)
  end
end
