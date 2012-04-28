class Service::JenkinsNew < Service
  self.title = 'Jenkins'

  NOTIFY_URL = '%s/git/notifyCommit'

  string :jenkins_url, :repo_base
  white_list :jenkins_url, :repo_base

  def receive_push
    if !data['jenkins_url'].present?
      raise_config_error "Jenkins URL not set"
    end

    url = NOTIFY_URL % data['jenkins_url'].sub(%r{/+$}, '')

    params = {
      :url => repo_url,
      :from => 'github'
    }

    params[:branch] = branch_name unless tag?

    http_get url, params
  end
end
