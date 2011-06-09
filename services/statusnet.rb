class Service::StatusNet < Service
  self.hook_name = :statusnet

  def receive_push
    repository = payload['repository']['name']
    statuses = Array.new

    if data['digest'] == '1'
      commit = payload['commits'][-1]
      tiny_url = shorten_url(payload['repository']['url'] + '/commits/' + payload['ref_name'])
      statuses.push "[#{repository}] #{tiny_url} #{commit['author']['name']} - #{payload['commits'].length} commits"
    else
      payload['commits'].each do |commit|
        tiny_url = shorten_url(commit['url'])
        statuses.push "[#{repository}] #{tiny_url} #{commit['author']['name']} - #{commit['message']}"
      end
    end

    http.url_prefix = data['server']
    http.basic_auth(data['username'], data['password'])
    statuses.each do |status|
      http_post '/api/statuses/update.xml',
        'status' => status, 'source' => 'github'
    end
  rescue Errno::ECONNREFUSED => boom
    raise_config_error "Connection refused. Invalid server configuration."
  end
end
