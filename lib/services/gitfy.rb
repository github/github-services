class Service::Gitfy < Service
  default_events :pull_request

  url "http://www.hashdog.com"
  logo_url "http://gitfy-design.herokuapp.com/img/logo.png"
  supported_by :web => 'http://www.hashdog.com/#contact'
  
  def receive_event

  end

end
