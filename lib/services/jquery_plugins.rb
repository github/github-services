class Service::JqueryPlugins < Service

  self.title = 'jQuery Plugins'

  url "http://plugins.jquery.com/"

  logo_url "http://plugins.jquery.com/jquery-wp-content/themes/jquery/images/logo-jquery.png"

  maintained_by :github => 'dwradcliffe', :twitter => 'dwradcliffe'

  supported_by :email => 'plugins@jquery.com'

  def receive_push
    http_post "http://plugins.jquery.com/postreceive-hook", :payload => generate_json(payload)
  end

end
