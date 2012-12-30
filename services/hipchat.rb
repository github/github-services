class Service::HipChat < Service
  string :auth_token, :room, :restrict_to_branch
  boolean :notify
  white_list :room, :restrict_to_branch

  default_events :commit_comment, :download, :fork, :fork_apply, :gollum,
    :issues, :issue_comment, :member, :public, :pull_request, :push, :watch

  def receive_event
    # make sure we have what we need
    raise_config_error "Missing 'auth_token'" if data['auth_token'].to_s == ''
    raise_config_error "Missing 'room'" if data['room'].to_s == ''

    branch = payload['ref'].split('/').last
    branch_restriction = data['restrict_to_branch'].to_s

    # check the branch restriction is poplulated and branch is not included
    if branch_restriction.length > 0 && branch_restriction.index(branch) == nil
      return
    end

    http.headers['X-GitHub-Event'] = event.to_s

    res = http_post "https://api.hipchat.com/v1/webhooks/github",
      :auth_token => data['auth_token'],
      :room_id => data['room'],
      :payload => JSON.generate(payload),
      :notify => data['notify'] ? 1 : 0
    if res.status < 200 || res.status > 299
      raise_config_error
    end
  end
end
