class Service::RDocInfo < Service::HttpPost

  default_events :push

  url 'http://www.rubydoc.info'

  maintained_by :github => 'zapnap'

  self.title = 'Rdocinfo'

  def receive_event
    deliver 'http://www.rubydoc.info/checkout'
  end
end
