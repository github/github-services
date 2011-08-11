class Service::Bugherd < Service
  string :url, :project_key

  def receive_push
    url = data['url'] || 'http://www.bugherd.com'
    http_post "#{url}/github_web_hook/#{data['project_key']}",
      :payload => JSON.generate(payload)
  end
end
