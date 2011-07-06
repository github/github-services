class Service::ReadTheDocs < Service
  def receive_push
    http_post "http://readthedocs.org/github", :payload => JSON.generate(payload)
  end
end

