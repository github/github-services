class Service::JenkinsGitHub < Service
  self.title = 'Jenkins (GitHub plugin)'
  self.hook_name = 'jenkins' # legacy hook name

  string :jenkins_hook_url
  white_list :jenkins_hook_url

  def receive_push
    if data['jenkins_hook_url'].present?
      url = data['jenkins_hook_url']
    else
      raise_config_error "Jenkins Github Webhook URL not set"
    end
    http_post url,
      :payload => JSON.generate(payload)
  end
end
