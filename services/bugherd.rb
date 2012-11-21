class Service::BugHerd < Service
  default_events :issues, :issue_comment, :push
  string :project_key
  white_list :project_key

  def receive_push
    if data['url'].present?
      url = data['url']
    else
      url = "http://www.bugherd.com/github_web_hook/#{data['project_key']}"
    end
    http_post url,
      :payload => JSON.generate(payload)
  end

  alias receive_issues receive_push
  alias receive_issue_comment receive_push

end
