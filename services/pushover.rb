class Service::Pushover < Service
  string :user_key, :device_name
  white_list :device_name

  def receive_push
    if !payload["commits"].any?
      return
    end

    if !data["user_key"]
      raise_config_error "Invalid Pushover user key."
    end

    url = URI.parse("https://api.pushover.net/1/messages.json")

    commits = payload["commits"].length
    repo = payload["repository"]["url"].split("/")[-2 .. -1].join("/")
    latest_message = payload["commits"].last["message"].split("\n").first
    if latest_message.length > 100
      latest_message = latest_message[0 ... 96] + "[..]"
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
      :token => "E6jpcJjaeASA7CWQ0cYjW6oP9N5xtJ",
      :user => data["user_key"],
      :device => data["device_name"],
      :title => title,
      :message => message,
      :url => latest_url,
      :url_title => "View commit on GitHub"
  end
end
