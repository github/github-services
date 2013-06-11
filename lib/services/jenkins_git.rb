class Service::JenkinsGit < Service
  self.title = 'Jenkins (Git plugin)'

  NOTIFY_URL = '%s/git/notifyCommit'

  string :jenkins_url
  white_list :jenkins_url

  def receive_push
    if !data['jenkins_url'].present?
      raise_config_error "Jenkins URL not set"
    end

    url = NOTIFY_URL % data['jenkins_url'].sub(%r{/+$}, '')

    params = {
      :url => repo_url,
      :from => 'github'
    }

    params[:branches] = branch_name unless tag?

    http.ssl[:verify] = false
    http.url_prefix = url
    http_get url, params
  end
end
