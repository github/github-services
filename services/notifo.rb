class Service::Notifo < Service
  self.hook_name = :notifo

  def receive_push
    subscribe_url = URI.parse('https://api.notifo.com/v1/subscribe_user')
    http.basic_auth 'github', secrets['notifo']['apikey']
    http.url_prefix = "https://api.notifo.com/v1"

    data['subscribers'].gsub(/\s/, '').split(',').each do |subscriber|
      http_post "subscribe_user", :username => subscriber

      commit = payload['commits'].last;
      if payload['commits'].length > 1
        extras = payload['commits'].length - 1
        http_post "send_notification",
          'to' => subscriber,
          'msg' => "#{commit['author']['name']}:  \"#{commit['message'].slice(0,40)}\" (+#{extras} more commits)",
          'title' => "#{payload['repository']['name']}/#{payload['ref_name']}",
          'uri' => payload['compare']
      else
        http_post "send_notification",
          'to' => subscriber,
          'msg' => "#{commit['author']['name']}:  \"#{commit['message']}\"",
          'title' => "#{payload['repository']['name']}/#{payload['ref_name']}",
          'uri' => commit['url']
      end
    end
  end
end
