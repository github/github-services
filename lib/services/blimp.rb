class Service::Blimp < Service
  string :project_url, :username, :goal_title

  password :api_key

  white_list :project_url, :username, :goal_title

  default_events :issues, :issue_comment

  url "http://getblimp.com"
  logo_url "http://getblimp.com/images/blimp.png"

  maintained_by :github => 'jpadilla'

  supported_by :email => 'support@getblimp.com',
    :github => 'jpadilla',
    :twitter => 'blimp'


  def receive_event
    ensure_required_data
    send_http_post
  end

  private
  def ensure_required_data
    data.each_pair do |setting, value|
      if setting != 'goal_title'
        raise_config_error "Missing '#{setting}'" if value.to_s == ''
      end
    end

    if data['goal_title'].to_s == ''
      repo_name = payload['repository']['name']
      owner_login = payload['repository']['owner']['login']
      data['goal_title'] = "Github Issues - #{owner_login}/#{repo_name}"
    end
  end

  private
  def send_http_post
    http.headers['X-Blimp-Username'] = data['username']
    http.headers['X-Blimp-API-Key'] = data['api_key']

    if data['project_url'] =~ %r{^https://app.getblimp.com/([-\w]+)/([-\w]+)/}
      company_url = $1
      project_url = $2
    else
      raise_config_error "That's not a URL to a Blimp project. " \
      "Navigate to the Blimp project you'd like to post to and note the URL."
    end

    params = {
      :event => event,
      :payload => payload,
      :company_url => company_url,
      :project_url => project_url,
      :goal_title => data['goal_title']
    }

    url = "https://app.getblimp.com/api/v2/github_service/"
    response = http_post url, generate_json(params)

    case response.status
    when 401; raise_config_error "Invalid Username + API Key"
    when 403; raise_config_error "No access to project"
    end
  end

end
