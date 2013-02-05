class Service::CoffeeDocInfo < Service
  self.title = 'CoffeeDoc.info'

  default_events :push

  url "http://coffeedoc.info/"

  maintained_by :github => 'pwnall'

  supported_by :web => 'https://github.com/netzpirat/coffeedoc.info',
               :twitter => 'netzpirat', :github => 'netzpirat'

  def receive_push
    http_post 'http://coffeedoc.info/checkout', :payload => payload.to_json
  end
end
