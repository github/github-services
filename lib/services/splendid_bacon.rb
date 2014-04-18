class Service::SplendidBacon < Service
  string :host_url, :project_id, :token
  white_list :project_id

  def receive_push
    token = data['token']
    project_id = data['project_id']
    http.url_prefix = 'http://{host_url}'
    http_post "/api/v1/projects/#{project_id}/github" do |req|
      req.params[:token] = token
      req.body = {:payload => generate_json(payload)}
    end
  end
end
