class Service::Gitfy < Service

  url "http://www.hashdog.com"
  logo_url "http://gitfy-design.herokuapp.com/img/logo.png"
  supported_by :web => 'http://www.hashdog.com/#contact'
  
  def receive_push
    http_post "http://gitfy-design.herokuapp.com/dashboard",
      :payload => generate_json(payload)
  end

end
