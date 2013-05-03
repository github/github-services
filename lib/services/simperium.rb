class Service::Simperium < Service::HttpPost
  string :app_id, :token, :bucket

  white_list :app_id, :bucket

  default_events :push, :issues, :issue_comment, :commit_comment,
    :pull_request, :pull_request_review_comment, :watch, :fork,
    :fork_apply, :member, :public, :team_add, :status

  url "https://simperium.com"
  logo_url "https://simperium.com/media/images/simperium_logo_black_sm.png"

  maintained_by :github => 'fredrocious',
    :twitter => '@fredrocious'

  supported_by :web => 'https://simperium.com/contact',
    :email => 'help@simperium.com',
    :twitter => '@simperium'

  def receive_event
    appid = required_config_value('app_id')
    token = required_config_value('token')
    bucket = required_config_value('bucket')

    if appid.match(/^[A-Za-z0-9-]+$/) == nil
      raise_config_error "Invalid app id"
    end

    if token.match(/^[A-Za-z0-9]+$/) == nil
      raise_config_error "Invalid token"
    end

    if bucket.match(/^[A-Za-z0-9\-\.@]+$/) == nil
      raise_config_error "Invalid bucket name"
    end

    wrap_http_errors do
      body = encode_body
      url = set_url "https://api.simperium.com:443/1/#{appid}/#{bucket}/i/#{delivery_guid}"
      http.headers['Authorization'] = "Token #{token}"

      http_post(url, body)
    end
  end
end

