class Service::Puppetlinter < Service

  def receive_push
    http_post \
      "http://www.puppetlinter.com/api/v1/hook",
      :payload => JSON.generate(payload)
  end
end
