class Service::PuppetLinter < Service

  def receive_push
    http_post \
      "http://www.puppetlinter.com/api/v1/hook",
      :payload => generate_json(payload)
  end
end
