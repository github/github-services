class Service::PiwikPlugins < Service::HttpPost

  self.title = 'Piwik Plugins'

  url "http://plugins.piwik.org/"

  logo_url "http://piwik.org/wp-content/themes/piwik/img/logo_mainpage.png"

  maintained_by :github => 'halfdan', :twitter => 'geekproject'

  supported_by :email => 'fabian@piwik.org'

  def receive_push
    deliver "http://plugins.piwik.org/postreceive-hook"
  end

end
