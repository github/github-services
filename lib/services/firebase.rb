class Service::Firebase < Service
  string :firebase, :secret
  white_list :firebase

  url 'https://www.firebase.com'
  logo_url 'https://www.firebase.com/images/logo.png'
  maintained_by :github => 'anantn'
  supported_by :email => 'support@firebase.com'

  def receive_push
    url = data['firebase'].to_s
    url.gsub! /\s/, ''

    if url.empty?
      raise_config_error 'Invalid URL.'
    end

    if url !~ /^https\:\/\//
      raise_config_error 'Invalid URL (did you include the https prefix?)'
    end

    if url !~ /^.*\.json$/
      url = url + '.json'
    end

    secret = data['secret'].to_s
    if secret.length > 0
      url = url + '?auth=' + secret
    end

    payload['commits'].each do |commit|
      http_post url, generate_json(commit)
    end
  rescue Addressable::URI::InvalidURIError, Errno::EHOSTUNREACH
    raise_missing_error $!.to_s
  rescue SocketError
    if $!.to_s =~ /getaddrinfo:/
      raise_missing_error 'Invalid host name.'
    else
      raise
    end
  rescue EOFError
    raise_config_error 'Invalid server response.'
  end
end
