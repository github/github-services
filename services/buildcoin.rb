class Service::Buildcoin < Service
  string :company_key

  default_events :push, :pull_request, :pull_request_review_comment

  def receive_event
    raise_config_error "Missing Company API Key" if data['company_key'].to_s == ''
    
    if event.to_s.eql? 'push'
      url = "https://buildcoin.com/hooks/#{data['company_key']}/github/push"
    elsif event.to_s.eql? 'pull_request'
      url = "https://buildcoin.com/hooks/#{data['company_key']}/github/pullrequest"
    elsif event.to_s.eql? 'pull_request_review_comment'
      url = "https://buildcoin.com/hooks/#{data['company_key']}/github/pullrequest/comment"
    end

    res = http_post url,
      {'payload' => payload.to_json}

    if res.status != 200
      raise_config_error
    end
  end
end
