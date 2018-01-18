class Service::PiwikPlugins < Service::HttpPost

  self.title = 'Matomo Plugins'

  url "https://plugins.matomo.org/"

  logo_url "https://matomo.org/wp-content/themes/piwik/img/logo_mainpage.png"

  maintained_by :github => 'matomo-org', :twitter => 'matomo_org'

  supported_by :email => 'hello@matomo.org'

  def receive_push
    deliver "https://plugins.matomo.org/postreceive-hook"
  end

end
