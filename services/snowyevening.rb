class Service::SnowyEvening < Service
  string :project, :api_key

  def receive_push
    http.ssl[:verify] = false
    res = http_post "https://snowy-evening.com/api/integration/github_commit/"+data['api_key']+"/"+data['project'],
      :payload => JSON.generate(payload)
    return
  end
end