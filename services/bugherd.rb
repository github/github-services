class Service::Bugherd < Service
  string :url, :project_key

  def receive_push
    if data['url'].present?
      url = data['url']
    else
      url = 'http://www.bugherd.com'
    end
    http_post "#{url}/github_web_hook/#{data['project_key']}",
      :payload => JSON.generate(payload)
  end
end
