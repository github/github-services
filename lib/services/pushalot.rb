class Service::Pushalot < Service
  string :authorization_token

  def receive_push
    if !payload["commits"].any?
      return
    end

    if !data["authorization_token"] or data["authorization_token"].length != 32
      raise_config_error "Invalid Pushalot authorization token."
    end

    url = URI.parse("https://pushalot.com/api/sendmessage")

    commits = payload["commits"].length
    repo = payload["repository"]["url"].split("/")[-2 .. -1].join("/")
    latest_message = payload["commits"].last["message"].split("\n").first
    if latest_message.length > 1000
      latest_message = latest_message[0 ... 997] + "..."
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
      :AuthorizationToken => data["authorization_token"],
      :Title => title,
      :Body => message,
      :Link => latest_url,
      :LinkTitle => "View commit on GitHub"
  end
end
