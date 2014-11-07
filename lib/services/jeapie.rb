class Service::Jeapie < Service::HttpPost
  password :token

  default_events :push, :pull_request, :commit_comment

  url "http://jeapie.com"
  logo_url "http://jeapie.com/images/icon48.png"

  maintained_by :github => 'Jeapie',
      :twitter => '@JeapieCom'

  supported_by :web => 'http://jeapie.com/en/site/contact',
      :email => 'jeapiecompany@gmail.com',
      :twitter => '@JeapieCom'

  def receive_event

    if !payload["commits"].any?
      return
    end

    token = required_config_value('token')

    if !token
      raise_config_error "Invalid Jeapie token."
    end

    url = URI.parse("https://api.jeapie.com/v2/broadcast/send/message.json")

    commits = payload["commits"].length
    repo = payload["repository"]["url"].split("/")[-2 .. -1].join("/")
    latest_message = payload["commits"].last["message"].split("\n").first
    if latest_message.length > 300
      latest_message = latest_message[0 ... 296] + "[..]"
    end
    latest_url = shorten_url(payload["commits"].last["url"])

    if commits == 1
      title = "#{payload["pusher"]["name"]} pushed to #{repo}"
      message = latest_message
    else
      title = "#{payload["pusher"]["name"]} pushed #{commits} " +
        "commit#{commits == 1 ? '' : 's'} to #{repo}"
      message = "Latest: #{latest_message}"
    end

    http_post url.to_s,
      :token => token,
      :title => title,
      :message => message
  end
end
