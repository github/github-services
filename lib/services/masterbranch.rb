class Service::Masterbranch < Service
  def receive_push
    http_post "http://webhooks.masterbranch.com/gh-hook",
      :payload => generate_json(payload)
  end
end

