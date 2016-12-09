class Service::Basecamp < Service
  SERVICE_NAME = 'GitHub'
  LOGO_URL     = 'https://asset1.37img.com/global/github/original.png'

  string          :project_url, :email_address
  password        :password
  white_list      :project_url, :email_address
  default_events  :push, :pull_request, :issues

  self.hook_name = 'bcx'

  def receive_push
    commit = payload['commits'].last || {}
    author = commit['author'] || commit['committer'] || payload['pusher']

    message = summary_message.sub("[#{repo_name}] #{pusher_name} ", '')
    create_event 'committed', message, summary_url, author['email']
  end

  def receive_pull_request
    base_ref = pull.base.label.split(':').last
    head_ref = pull.head.label.split(':').last
    head_ref = pull.head.label if head_ref == base_ref

    create_event "#{action} a pull request",
      "#{pull.title} (#{base_ref}..#{head_ref})",
      pull.html_url
  end

  def receive_issues
    create_event "#{action} an issue", issue.title, issue.html_url
  end

  private

  def create_event(action, message, url, author_email = nil)
    http_post_event :service => SERVICE_NAME,
      :logo_url => LOGO_URL,
      :creator_email_address => author_email,
      :description => action,
      :title => message,
      :url => url
  end

  def http_post_event(params)
    http.basic_auth data['email_address'], data['password']
    http.headers['User-Agent']    = 'GitHub service hook'
    http.headers['Content-Type']  = 'application/json'
    http.headers['Accept']        = 'application/json'

    response = http_post(events_api_url, generate_json(params))

    case response.status
    when 401; raise_config_error "Invalid email + password: #{response.body.inspect}"
    when 403; raise_config_error "No access to project: #{response.body.inspect}"
    when 404; raise_config_error "No such project: #{response.body.inspect}"
    when 422; raise_config_error "Validation error: #{response.body.inspect}"
    end
  end

  EVENTS_API_URL = 'https://basecamp.com:443/%d/api/v1/projects/%d/events.json'
  def events_api_url
    if data['project_url'] =~ %r{^https://basecamp\.com/(\d+)/projects/(\d+)}
      EVENTS_API_URL % [$1, $2]
    elsif data['project_url'] =~ /basecamphq\.com/
      raise_config_error "That's a URL for a Basecamp Classic project, not the new Basecamp. Check out the Basecamp Classic service hook instead!"
    else
      raise_config_error "That's not a URL to a Basecamp project! Navigate to the Basecamp project you'd like to post to and note the URL. It should look something like: https://basecamp.com/123456/projects/7890123 -- paste that URL here."
    end
  end
end
