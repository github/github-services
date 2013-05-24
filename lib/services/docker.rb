class Service::Docker < Service
  def receive_push
    http_post "https://index.docker.io/hooks/github", :payload => generate_json(payload)
  end
end

