class Service::CoffeeDocInfo < Service::HttpPost
  self.title = 'CoffeeDoc.info'

  default_events :push

  url "http://coffeedoc.info/"

  maintained_by :github => 'pwnall', :twitter => '@pwnall'

  supported_by :web => 'https://github.com/netzpirat/coffeedoc.info',
               :twitter => 'netzpirat', :github => 'netzpirat'

  def receive_event
    url = 'http://coffeedoc.info/checkout'
    deliver url
  end
end
