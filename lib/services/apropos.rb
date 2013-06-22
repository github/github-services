
class Service::Apropos < Service
  default_events :commit_comment, :issues, :issue_comment, :pull_request, :push
  string         :project_id
  
  def apropos_url
    "http://www.apropos.io/api/v1/githook/#{data['project_id']}"
  end
  
  def receive_commit_comment
    http.headers['content-type'] = 'application/json'
    http.headers['X-Github-Event'] = 'commit_comment'
    http_post apropos_url, generate_json(payload)
  end
  
  def receive_issue_comment
    http.headers['content-type'] = 'application/json'
    http.headers['X-Github-Event'] = 'issue_comment'
    http_post apropos_url, generate_json(payload)
  end
  
  def receive_pull_request
    http.headers['content-type'] = 'application/json'
    http.headers['X-Github-Event'] = 'pull_request'
    http_post apropos_url, generate_json(payload)
  end
  
  def receive_push
    http.headers['content-type'] = 'application/json'
    http.headers['X-Github-Event'] = 'push'
    http_post apropos_url, generate_json(payload)
  end

end
