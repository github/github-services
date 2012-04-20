class Service::Notifo < Service
  string :subscribers
  white_list :subscribers

  def receive_push
    return if Array(payload['commits']).size == 0

    subscribe_url = URI.parse('https://api.notifo.com/v1/subscribe_user')
    http.basic_auth 'github', secrets['notifo']['apikey']
    http.url_prefix = "https://api.notifo.com/v1"

    subscribers = data['subscribers'].to_s

    if subscribers.empty?
      raise_config_error "No subscribers: #{subscribers.inspect}"
      return
    end

    subscribers.gsub(/\s/, '').split(',').each do |subscriber|
      http_post "subscribe_user", :username => subscriber

      commit = payload['commits'].last;
      author = commit['author'] || {}

      if payload['commits'].length > 1
        extras = payload['commits'].length - 1
        http_post "send_notification",
          'to' => subscriber,
          'msg' => "#{author['name']}:  \"#{commit['message'].slice(0,40)}\" (+#{extras} more commits)",
          'title' => "#{payload['repository']['name']}/#{ref_name}",
          'uri' => payload['compare']
      else
        http_post "send_notification",
          'to' => subscriber,
          'msg' => "#{author['name']}:  \"#{commit['message']}\"",
          'title' => "#{payload['repository']['name']}/#{ref_name}",
          'uri' => commit['url']
      end
    end
  end
end
