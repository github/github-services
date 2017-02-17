class Service::Pushsafer < Service
  string :private_key, :device_id, :icon, :sound, :vibration, :time2live
  white_list :device_id, :icon, :sound, :vibration, :time2live

  def receive_push
    if !payload["commits"].any?
      return
    end

    if !data["private_key"]
      raise_config_error "Invalid Pushsafer private or alias key."
    end

    url = URI.parse("https://www.pushsafer.com/api")

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
      :k => data["private_key"],
      :d => data["device_id"],
	  :i => data["icon"],
	  :s => data["sound"],
	  :v => data["vibration"],
	  :l => data["time2live"],
      :t => title,
      :m => message,
      :u => latest_url,
      :ut => "View commit on GitHub"
  end
end
