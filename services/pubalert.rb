class Service::PubAlert < Service
  #
  # Post to URL when Repo toggles from Private to Public
  #

  string :remote_url,
    # (Required) The remote URL to POST data towards (eg: "https://com.example/webhook/github"
    :auth_token,
    # (Required) Authentication Token to be used by the POST URL
    :repo_name
    # (Required) Repo name which triggered this Event.

  default_events :public

  def receive_public
    # make sure we have what we need
    raise_config_error "Missing 'remote_url'" if data['remote_url'].to_s == ''
    raise_config_error "Missing 'auth_token'" if data['auth_token'].to_s == ''
    raise_config_error "Missing 'repo_name'" if data['repo_name'].to_s == ''

    # Set our headers
    http.headers['X-GitHub-Event'] = event.to_s #this should be 'public' anyway

    res = http_post "#{data['remote_url']}",{
      :auth_token => data['auth_token'],
      :repo_name => data['repo_name']
        }
    if res.status < 200 || res.status > 299
      raise_config_error
    end
  end
end
