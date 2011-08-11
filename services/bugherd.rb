class Service::Bugherd < Service
  string :project_key

  def receive_push
    if data['url'].present?
      url = data['url']
    else
      url = 'http://www.bugherd.com/github_web_hook/' + data['project_key']
    end
    http_post url,
      :payload => JSON.generate(payload)
  end
end
