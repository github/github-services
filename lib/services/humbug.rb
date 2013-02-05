class Service::Humbug < Service
  string :email
  string :api_key

  white_list :email

  default_events :commit_comment, :create, :delete, :download, :follow, :fork,
    :fork_apply, :gist, :gollum, :issue_comment, :issues, :member, :public,
    :pull_request, :push, :team_add, :watch, :pull_request_review_comment,
    :status

  def receive_event
    raise_config_error "Missing 'email'" if data['email'].to_s == ''
    raise_config_error "Missing 'api_key'" if data['api_key'].to_s == ''

    res = http_post "https://humbughq.com/api/v1/external/github",
      :email => data['email'],
      'api-key' => data['api_key'],
      :event => event,
      :payload => JSON.generate(payload)
    if not res.success?
      raise_config_error ("Server returned status " + res.status.to_s +
                          ": " + res.body)
    end
  end
end
