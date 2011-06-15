class Service::Redmine < Service
  def receive_push
    http.ssl[:verify] = false
    http.url_prefix = data['address']
    http_get "sys/fetch_changesets" do |req|
      req.params['key'] = data['api_key']
      req.params['id']  = data['project']
    end
  end
end

