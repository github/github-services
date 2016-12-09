class Service::HuBoard < Service::HttpPost

  default_events :issue_comment, :issues

  url "https://huboard.com"
  logo_url "https://huboard.com/img/LogoFullPurpleLight.png"
  maintained_by :github => 'rauhryan'
  supported_by :email => 'support@huboard.com'

  HUBOARD_URL = "https://huboard.com/api/site"

  def receive_issues
    http_post "#{HUBOARD_URL}/webhook/issue", :payload => generate_json(payload)
  end

  def receive_issue_comment
    http_post "#{HUBOARD_URL}/webhook/comment", :payload => generate_json(payload)
  end

end

