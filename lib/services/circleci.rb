class Service::Circleci < Service

  url "https://circleci.com"
  logo_url "https://circleci.com/favicon.ico"

  maintained_by :github => 'circleci'
  supported_by  :web => 'https://circleci.com/about',
  :email => 'sayhi@circleci.com'

  default_events Service::ALL_EVENTS


  def receive_event

    http.headers['content-type'] = 'application/x-www-form-urlencoded'
    http_post circleci_url, "payload" => JSON.generate(payload) , "event_type" =>  JSON.generate({ :event_type => self.event })
    
  end


  private

  def circleci_url
    "https://circleci.com/hooks/github" 
  end
end
