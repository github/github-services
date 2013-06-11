class Service::GitLive < Service
  self.title = 'gitlive'
  def receive_push
    http_post 'http://gitlive.com/hook',
      :payload => generate_json(payload)
  end
end
