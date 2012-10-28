class Service::CoffeeDocInfo < Service
  self.title = 'CoffeeDoc.info'

  def receive_push
    http_post 'http://coffeedoc.info/checkout', :payload => payload.to_json
  end
end
