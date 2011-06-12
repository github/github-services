class Service::CoOp < Service
  def receive_push
    repository = payload['repository']['name']
    payload['commits'].each do |commit|
      status = "#{commit['author']['name']} just committed a change to #{repository} on GitHub: #{commit['message']} (#{commit['url']})"
      res = http_post "http://coopapp.com/groups/%s/notes" % [data['group_id']],
        {:status => status, :key => data['token']}.to_json,
        'Accept'        => 'application/json',
        'Content-Type'  => 'application/json; charset=utf-8',
        'User-Agent'    => 'GitHub Notifier'

      if res.status >= 400
        raise_config_error
      end
    end
  end
end
