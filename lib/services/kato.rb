class Service::Kato < Service::HttpPost
  hook_name 'lechat'
  string :webhook_url
  boolean :ignore_commits, :ignore_commit_comments, :ignore_issues, :ignore_issue_comments, :ignore_pull_requests, :ignore_pull_request_review_comments, :ignore_wiki_page_updates

  # include 'webhook_url' in the debug logs
  white_list :webhook_url

  default_events Service::ALL_EVENTS

  url "https://kato.im/"

  maintained_by :github => 'JLarky'

  supported_by :email => 'support@kato.im'

  def receive_event
    ignore_flag = case event.to_s
      when 'push' then 'ignore_commits'
      when 'gollum' then 'ignore_wiki_page_updates'
      when 'issues' then 'ignore_issues'
      else 'ignore_'+event.to_s+'s'
    end
    return if data[ignore_flag]

    webhook_url = required_config_value('webhook_url')

    res = deliver webhook_url

    if res.status < 200 || res.status > 299
      raise_missing_error "Unexpected response code:#{res.status}"
    end
  end
end
