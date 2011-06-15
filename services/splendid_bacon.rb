class Service::SplendidBacon < Service
  def receive_push
    token = data['token']
    project_id = data['project_id']
    http.ssl[:verify] = false
    http.url_prefix = 'https://splendidbacon.com'
    http_post "/api/v1/projects/#{project_id}/github" do |req|
      req.params[:token] = token
      req.body = {:payload => payload.to_json}
    end
  end
end
