class Service::Jabwire < Service

  string :project_id
  string :apikey

  url 'https://www.jabwire.com/'
  logo_url 'https://www.jabwire.com/assets/jabwire_logo.png'
  maintained_by :github => 'dshimy'
  supported_by :web => 'https://jabwire.uservoice.com/knowledgebase'

  def receive_push
    http.ssl[:verify] = false
    http_post "https://www.jabwire.com/projects/#{project_id}/webhook.json" do |req|
      req.params[:apikey] = apikey
      req.headers['Content-Type'] = 'application/json'
      req.body = JSON.generate({:payload => payload})
    end
  end

  def project_id
    data["project_id"].to_s.strip
  end

  def apikey
    data["apikey"].to_s.strip
  end

end
