class Service::Gitter < Service::HttpPost
  password :token
  boolean :mute_fork, :mute_watch, :mute_comments, :mute_wiki

  default_events ALL_EVENTS

  url      'https://gitter.im'
  logo_url 'https://gitter.im/_s/1/images/2/gitter/logo-blue-text.png'

  maintained_by github:  'malditogeek',
                twitter: '@malditogeek'

  supported_by github:   'gitterHQ',
               twitter:  '@gitchat',
               email:    'support@gitter.im'

  def receive_event
    token = required_config_value('token')
    raise_config_error 'Invalid token' unless token.match(/^\w+$/)

    return if data['mute_fork']     && event.to_s =~ /fork/
    return if data['mute_watch']    && event.to_s =~ /watch/
    return if data['mute_comments'] && event.to_s =~ /comment/
    return if data['mute_wiki']     && event.to_s =~ /gollum/

    http.headers['X-GitHub-Event'] = event.to_s

    deliver "https://webhooks.gitter.im/e/#{token}"
  end
end
