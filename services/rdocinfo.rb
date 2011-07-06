class Service::RDocInfo < Service
  self.title = 'Rdocinfo'

  def receive_push
    http_post 'http://rubydoc.info/checkout', :payload => payload.to_json
  end
end
