class Service::JenkinsGitHub < Service
  self.title = 'Jenkins (GitHub plugin)'
  self.hook_name = 'jenkins' # legacy hook name

  string :jenkins_hook_url
  white_list :jenkins_hook_url

  def receive_push
    if data['jenkins_hook_url'].present?
      url = data['jenkins_hook_url']
    else
      raise_config_error "Jenkins Hook Url not set"
    end
    http.ssl[:verify] = false # :(
    http.url_prefix = url
    http.headers['X-GitHub-Event'] = "push"
    http_post url,
      :payload => generate_json(payload)
  end
end
