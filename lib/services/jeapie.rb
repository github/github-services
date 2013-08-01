class Service::Jeapie < Service
  string :token

  def receive_push
    if !payload["commits"].any?
      return
    end

    if !data["token"]
      raise_config_error "Invalid Jeapie token."
    end

    url = URI.parse("https://api.jeapie.com/v1/broadcast/send/message.json")

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
      :token => data["token"],
      :title => title,
      :message => message,
  end
end
