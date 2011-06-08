class Service::GitLive < Service
  self.hook_name = :gitlive

  def receive_push
    http_post 'http://gitlive.com/hook',
      :payload => JSON.generate(payload)
  end
end
