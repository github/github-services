class Service::ReviewNinja < Service::HttpPost
  password :token
  string :domain

  white_list :domain

  default_events :pull_request, :issues, :issue_comment, :status

  url 'http://review.ninja'
  logo_url 'http://app.review.ninja/assets/images/review-ninja-250.png'

  maintained_by :github => 'dfarr'

  supported_by :web => 'http://review.ninja',
    :email => 'contact@review.ninja',
    :twitter => '@review_ninja'

  def receive_event
    token = required_config_value('token')
    domain = required_config_value('domain')

    http.headers['X-GitHub-Event'] = event.to_s

    if token.match(/^[A-Za-z0-9]+$/) == nil
      raise_config_error 'Invalid token'
    end

    if domain.match(/^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?$/) == nil
      raise_config_error 'Invalid domain'
    end

    deliver domain + '/github/service'
  end
end
