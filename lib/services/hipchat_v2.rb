class Service::HipChat_v2 < Service
  string :auth_token, :room, :restrict_to_branch
  boolean :notify, :quiet_fork, :quiet_watch, :quiet_comments, :quiet_wiki
  white_list :room, :restrict_to_branch

  default_events :commit_comment, :download, :fork, :fork_apply, :gollum,
    :issues, :issue_comment, :member, :public, :pull_request, :pull_request_review_comment,
    :push, :watch

  def receive_event
    # make sure we have what we need
    raise_config_error "Missing 'auth_token'" if data['auth_token'].to_s == ''
    raise_config_error "Missing 'room'" if data['room'].to_s == ''

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
    http.headers['Content-Type'] = 'application/json'
    
    rooms = data['room'].to_s.split(",")
    room_ids = if rooms.all? { |room_id| Integer(room_id) rescue false }
      rooms
    else
      [data['room'].to_s]
    end

    room_ids.each do |room_id|
      url = "https://api.hipchat.com:443/v2/room/#{room_id}/notification?auth_token=#{data['auth_token']}"
      res = http_post url, generate_json({
        :message => event.to_s,
        :notify => data['notify'] ? 1 : 0
      })
      if res.status < 200 || res.status > 299
        raise_config_error "Status: #{res.status}, Response: #{res.body.inspect}"
      end
    end
  end
end
