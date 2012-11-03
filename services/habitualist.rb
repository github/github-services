class Service::Habitualist < Service
  def receive_push
    http_post "https://habitualist.com/webhooks/github/",
      :payload => JSON.generate(payload)
  end
end
