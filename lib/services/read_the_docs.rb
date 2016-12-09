class Service::ReadTheDocs < Service
  def receive_push
    http_post "https://readthedocs.org/github", :payload => generate_json(payload)
  end
end

