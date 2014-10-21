class Service::Foxytask < Service::HttpPost
  url "http://www.foxytask.com"
  logo_url "http://www.foxytask.com/img/FoxNegatif.png"

  default_events :issues, :issue_comment, :public

  maintained_by github: 'akta3d'
  supported_by  web: 'http://www.foxytask.com',
                email: 'support@intia.fr'

  def receive_event
	http.headers['content-type'] = 'application/json'
    http_post foxytask_url, payload: generate_json(payload)
  end
  
  private

  def foxytask_url
    "http://www.foxytask.com/webhook"
  end
end
