class Service::Typetalk < Service::HttpPost
  string :client_id, :topic, :restrict_to_branch
  password :client_secret
  white_list :topic, :restrict_to_branch

  default_events :push, :pull_request

  url "http://typetalk.in"
  logo_url "https://deeb7lj8m1sjw.cloudfront.net/1.3.5/assets/images/common/logo.png"

  def receive_push
    check_config()

    branch = payload['ref'].split('/').last
    branch_restriction = data['restrict_to_branch'].to_s
    if branch_restriction.length > 0 && branch_restriction.index(branch) == nil
      return
    end
    send_message(format_pushed_message(payload))
  end

  def receive_pull_request
    check_config()

    send_message(format_pull_request_message(payload))
  end

  def check_config
    raise_config_error "Missing 'client_id'"     if data['client_id'].to_s == ''
    raise_config_error "Missing 'client_secret'" if data['client_secret'].to_s == ''
    raise_config_error "Missing 'topic'"         if data['topic'].to_s == ''
  end

  def send_message(message)
    http.url_prefix = 'https://typetalk.in'
    http.headers['X-GitHub-Event'] = event.to_s
    
    # get an access_token
    res = http_post '/oauth2/access_token',
                    { :client_id     => data['client_id'],
                      :client_secret => data['client_secret'],
                      :grant_type    => 'client_credentials',
                      :scope         => 'topic.post',}

    json = JSON.parse(res.body)
    http.headers['Authorization'] = "Bearer #{json['access_token']}"

    topics = data['topic'].to_s.split(",")
    topics.each do |topic|
      params = {
        :message => message
      }
      res = http_post "/api/v1/topics/#{topic}", params
      if res.status < 200 || res.status > 299
        raise_config_error
      end
    end
  end

  def format_pushed_message(payload)
    branch = payload['ref'].split('/').last
    return "#{payload['pusher']['name']} has pushed #{payload['commits'].size} commit(s) to #{branch} at #{payload['repository']['name']}\n#{payload['compare']}"
  end
  def format_pull_request_message(payload)
    return "#{payload['sender']['login']} #{payload['action']} pull request \##{payload['pull_request']['number']}: #{payload['pull_request']['title']}\n#{payload['pull_request']['html_url']}"
  end

end
