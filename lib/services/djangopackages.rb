class Service::DjangoPackages < Service::HttpPost
  
  default_events :push

  url "https://www.djangopackages.com/"
  logo_url "https://s3.amazonaws.com/opencomparison/img/logo_squares.png"

  maintained_by :github => 'pydanny',
    :twitter => '@pydanny'

  supported_by :email => 'pydanny@gmail.com',
    :twitter => '@pydanny'

  # ssl_version 2

  def receive_push
    url = "https://www.djangopackages.com/packages/github-webhook/"
    http_post url, :payload => generate_json(payload)
  end
end
