class Service::ReadTheDocs < Service
  self.hook_name = :read_the_docs

  def receive_push
    http_post "http://readthedocs.org/github", :payload => JSON.generate(payload)
  end
end

