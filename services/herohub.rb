class Service::HeroHub < Service
  string :deployerApp_identifier
  
  def receive_push
    raise_config_error 'Missing DeployerApp Identifier' if data['deployerApp_identifier'].to_s.empty?
    http_post "http://#{data['deployerApp_identifier']}.herokuapp.com/deploy/github",
      JSON.generate(payload)
    return
  end
end