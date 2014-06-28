require File.expand_path('../web', __FILE__)

class Service::Codereviewhub < Service::Web
  self.title = "CodeReviewHub"
  url "https://www.codereviewhub.com"
  logo_url "https://www.codereviewhub.com/favicon.ico"

  supported_by :email => 'contact@codereviewhub.com'
  maintained_by :github => 'codereviewhub'
  default_events :pull_request, :issue_comment, :commit_comment, :pull_request_review_comment
end
