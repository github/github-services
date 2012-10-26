require 'uri'

class Service::GitHubPages < Service
  default_events :commit_comment, :gollum, :issues, :issue_comment, :push
  boolean :gollum
  boolean :issues
  boolean :issue_comment
  boolean :push
  boolean :commit_comment

  def receive_event
    if data[event.to_s].to_i == 1
      http_post "https://api.github.com/secret/", JSON.generate(payload)
    end
  end
end
