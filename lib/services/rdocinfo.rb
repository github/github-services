class Service::RDocInfo < Service::HttpPost

  default_events :push

  title 'RubyDoc.info'
  url 'http://www.rubydoc.info'

  maintained_by :github => 'zapnap'

  supported_by :web => 'http://www.rubydoc.info', :github => 'zapnap'

  def receive_event
    deliver 'http://www.rubydoc.info/checkout'
  end
end
