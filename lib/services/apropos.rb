
class Service::Apropos < Service::HttpPost
  default_events :commit_comment, :issues, :issue_comment, :pull_request, :push
  string         :project_id
  
  def apropos_url
    proj_id = appid = required_config_value('project_id')
    "http://www.apropos.io/api/v1/githook/#{proj_id}"
  end
  
  def receive_commit_comment
    http.headers['content-type'] = 'application/json'
    http.headers['X-Github-Event'] = 'commit_comment'
    deliver apropos_url
  end
  
  def receive_issue_comment
    http.headers['content-type'] = 'application/json'
    http.headers['X-Github-Event'] = 'issue_comment'
    deliver apropos_url
  end
  
  def receive_pull_request
    http.headers['content-type'] = 'application/json'
    http.headers['X-Github-Event'] = 'pull_request'
    deliver apropos_url
  end

  def receive_issues
    http.headers['content-type'] = 'application/json'
    http.headers['X-Github-Event'] = 'issues'
    deliver apropos_url
  end
  
  def receive_push
    http.headers['content-type'] = 'application/json'
    http.headers['X-Github-Event'] = 'push'
    deliver apropos_url
  end

end
