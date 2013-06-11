class Service::Humbug < Service
  string :email
  string :api_key
  string :stream
  string :branches

  white_list :email
  white_list :branches

  default_events :commit_comment, :create, :delete, :download, :follow, :fork,
    :fork_apply, :gist, :gollum, :issue_comment, :issues, :member, :public,
    :pull_request, :push, :team_add, :watch, :pull_request_review_comment,
    :status

  def receive_event
    raise_config_error "Missing 'email'" if data['email'].to_s == ''
    raise_config_error "Missing 'api_key'" if data['api_key'].to_s == ''

    # url = 'http://localhost:9991/api/v1/external/github'
    url = 'https://humbughq.com/api/v1/external/github'
    res = http_post url,
      :email => data['email'],
      'api-key' => data['api_key'],
      'stream' => data['stream'],
      'branches' => data['branches'],
      :event => event,
      :payload => generate_json(payload)
    if not res.success?
      raise_config_error ("Server returned status " + res.status.to_s +
                          ": " + res.body)
    end
  end
end
