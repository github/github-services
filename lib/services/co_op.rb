class Service::CoOp < Service
  string :group_id, :token
  white_list :group_id

  self.title = 'Co-Op'

  def receive_push
    repository = payload['repository']['name']
    payload['commits'].each do |commit|
      status = "#{commit['author']['name']} just committed a change to #{repository} on GitHub: #{commit['message']} (#{commit['url']})"
      res = http_post "http://coopapp.com/groups/%s/notes" % [data['group_id']],
        generate_json(:status => status, :key => data['token']),
        'Accept'        => 'application/json',
        'Content-Type'  => 'application/json; charset=utf-8',
        'User-Agent'    => 'GitHub Notifier'

      if res.status >= 400
        raise_config_error
      end
    end
  end
end
