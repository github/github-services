class Service::GitLive < Service
  def receive_push
    http_post 'http://gitlive.com/hook',
      :payload => JSON.generate(payload)
  end
end
