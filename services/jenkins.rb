class Service::Jenkins < Service
  string :jenkins_hook_url

  def receive_push
    if data['jenkins_hook_url'].present?
      url = data['jenkins_hook_url']
    else
       raise_config_error "Jenkins Github Webhook url not set"
    end
    http_post url,
      :payload => JSON.generate(payload)
  end
end