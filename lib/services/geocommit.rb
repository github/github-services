class Service::GeoCommit < Service
  self.title = 'geocommit'
  def receive_push
    http.headers['Content-Type'] = 'application/githubpostreceive+json'
    http_post 'http://hook.geocommit.com/api/github',
      generate_json(payload)
  end
end
