class Service::HipChat < Service
  password :auth_token
  string :room, :restrict_to_branch, :color, :server
  boolean :notify, :quiet_fork, :quiet_watch, :quiet_comments, :quiet_wiki
  white_list :room, :restrict_to_branch, :color

  default_events :commit_comment, :download, :fork, :fork_apply, :gollum,
    :issues, :issue_comment, :member, :public, :pull_request, :pull_request_review_comment,
    :push, :watch

  def receive_event
    # make sure we have what we need
    raise_config_error "Missing 'auth_token'" if data['auth_token'].to_s == ''
    raise_config_error "Missing 'room'" if data['room'].to_s == ''

    server = data['server'].presence || 'api.hipchat.com'

    # push events can be restricted to certain branches
    if event.to_s == 'push'
      branch = payload['ref'].split('/').last
      branch_restriction = data['restrict_to_branch'].to_s

      # check the branch restriction is poplulated and branch is not included
      if branch_restriction.length > 0 && branch_restriction.index(branch) == nil
        return
      end
    end

    # ignore forks and watches if boolean is set
    return if event.to_s =~ /fork/ && data['quiet_fork']
    return if event.to_s =~ /watch/ && data['quiet_watch']
    return if event.to_s =~ /comment/ && data['quiet_comments']
    return if event.to_s =~ /gollum/ && data['quiet_wiki']

    http.headers['X-GitHub-Event'] = event.to_s

    rooms = data['room'].to_s.split(",")
    room_ids = if rooms.all? { |room_id| Integer(room_id) rescue false }
      rooms
    else
      [data['room'].to_s]
    end

    room_ids.each do |room_id|
      params = {
        :auth_token => data['auth_token'],
        :room_id => room_id,
        :payload => generate_json(payload),
        :notify => data['notify'] ? 1 : 0
      }
      if data['color'].present?
        params.merge!(:color => data['color'])
      end
      res = http_post "https://#{server}/v1/webhooks/github", params
      if res.status < 200 || res.status > 299
        raise_config_error
      end
    end
  end
end
