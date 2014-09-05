require File.expand_path('../web', __FILE__)

class Service::Reviewable < Service::Web
  self.title = 'Reviewable'
  url 'https://reviewable.io'
  logo_url 'https://reviewable.io/favicon-96x96.png'

  supported_by :email => 'support@reviewable.io'
  maintained_by :github => 'reviewable'
  default_events :pull_request, :issue_comment, :pull_request_review_comment
end
