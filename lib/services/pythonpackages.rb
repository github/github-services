class Service::PythonPackages < Service
  def receive_push
    http_post "https://pythonpackages.com/github", :payload => JSON.generate(payload)
  end
end
