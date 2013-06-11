class Service::RDocInfo < Service
  self.title = 'Rdocinfo'

  def receive_push
    http_post 'http://rubydoc.info/checkout', :payload => generate_json(payload)
  end
end
