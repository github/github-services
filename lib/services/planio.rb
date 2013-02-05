class Service::Planio < Service
  string :address, :project, :api_key
  white_list :address, :project

  def receive_push
    http.ssl[:verify] = true
    http.url_prefix = data['address']
    http_get "sys/fetch_changesets" do |req|
      req.params['key'] = data['api_key']
      req.params['id']  = data['project']
    end
  end
end

