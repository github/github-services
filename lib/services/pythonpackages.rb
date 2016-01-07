class Service::PythonPackages < Service
  def receive_push
    http_post "https://pythonpackages.com/github", :payload => generate_json(payload)
  end
end
