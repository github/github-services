class Service::GeoCommit < Service
  self.hook_name = :geocommit

  def receive_push
    http.headers['Content-Type'] = 'application/githubpostreceive+json'
    http_post 'http://hook.geocommit.com/api/github',
      JSON.generate(payload)
  end
end
