class Service::GitLive < Service
  self.title = 'sourcemint'
  def receive_push
    http_post 'http://api.sourcemint.com/actions/post-commit',
      :payload => JSON.generate(payload)
  end
end
