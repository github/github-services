class Service::Pushover < Service
  string :user_key, :device_name
  boolean :pull_request, :issues, :push
  white_list :device_name

  default_events :push, :issues, :issue_comment, :commit_comment,
    :pull_request, :pull_request_review_comment

  url = URI.parse('https://pushover.net/')
  logo_url 'https://pushover.net/images/icon-96.png'

  def receive_event
    if payload['commits'] and payload['commits'].any? and data['push']
      # :push
      commits = payload['commits'].length
      repo = payload['repository']["url"].split("/")[-2 .. -1].join("/")
      latest_message = payload['commits'].last['message'].split("\n").first
      if latest_message.length > 100
        latest_message = latest_message[0 ... 96] + "[..]"
      end
      latest_url = shorten_url(payload['commits'].last['url'])

      if commits == 1
        title = "#{payload['pusher']['name']} pushed to #{repo}"
        message = latest_message
      else
        title = "#{payload["pusher"]["name"]} pushed #{commits} " +
          "commit#{commits == 1 ? '' : 's'} to #{repo}"
        message = "Latest: #{latest_message}"
      end
    elsif payload['pull_request'] and data['pull_request']
      # :pull_request
      number = payload['pull_request']['number'].to_s
      title = [payload['sender'],payload['action'],'pull request',number].join(' ')
      message = payload['pull_request']['title']
      latest_url = payload['pull_request']['html_url']
    elsif payload['issue'] and data['issues']
      # :issues
      number = payload['issue']['number'].to_s
      title = [payload['sender'],payload['action'],'issue',number].join(' ')
      message = payload['issue']['title']
      latest_url = payload['repository']['url'] + '/issues' + number
    else
      return
    end

    if !data['user_key']
      raise_config_error 'Invalid Pushover user key.'
    end

    url = URI.parse('https://api.pushover.net/1/messages.json')

    http_post url.to_s,
      :token     => 'E6jpcJjaeASA7CWQ0cYjW6oP9N5xtJ',
      :user      => data['user_key'],
      :device    => data['device_name'],
      :title     => title,
      :message   => message,
      :url       => latest_url,
      :url_title => 'View on GitHub'
  end
end
