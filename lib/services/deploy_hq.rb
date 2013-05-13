class Service::DeployHq < Service
  string :deploy_hook_url
  boolean :email_pusher
  
  url "http://www.deployhq.com/"
  logo_url "http://www.deployhq.com/images/deploy/logo.png"
  maintained_by :github => 'darkphnx'
  supported_by :web => 'http://support.deployhq.com/', :email => 'support@deployhq.com'

  def receive_push
    unless data['deploy_hook_url'].to_s =~ /^https:\/\/[a-z0-9\-\_]+\.deployhq.com\/deploy\/[a-z0-9\-\_]+\/to\/[a-z0-9\-\_]+\/[a-z0-9]+$/i
      raise_config_error "Deploy Hook invalid" 
    end
    email_pusher = data['email_pusher'] == "1"

    http.url_prefix = data['deploy_hook_url']
    http.headers['content-type'] = 'application/x-www-form-urlencoded'
    body = Faraday::Utils.build_nested_query(http.params.merge(:payload => generate_json(payload), :notify => email_pusher))

    http_post data['deploy_hook_url'], body
  end

end
