class Service::HuBoard < Service::HttpPost

  default_events :issue_comment, :issues

  url "https://huboard.com"
  logo_url "https://huboard.com/img/LogoFullPurpleLight.png"
  maintained_by :github => 'rauhryan'
  supported_by :email => 'huboard@huboard.com'

  HUBOARD_URL = "http://live.huboard.com"

  def receive_issues
    http_post "#{HUBOARD_URL}/issue/webhook", :payload => generate_json(payload)
  end

  def receive_issue_comment
    http_post "#{HUBOARD_URL}/comment/webhook", :payload => generate_json(payload)
  end

end

