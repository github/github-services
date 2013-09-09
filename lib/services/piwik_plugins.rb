class Service::PiwikPlugins < Service

  self.title = 'Piwik Plugins'

  url "http://plugins.piwik.org/"

  logo_url "http://piwik.org/wp-content/themes/piwik/img/logo_mainpage.png"

  maintained_by :github => 'halfdan', :twitter => 'geekproject'

  supported_by :email => 'fabian@piwik.org'

  def receive_push
    http_post "http://plugins.piwik.org/postreceive-hook", :payload => generate_json(payload)
  end

end
