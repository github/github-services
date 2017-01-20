class Service::Weblate < Service
  string :url
  white_list :url

  url "http://weblate.org/"
  logo_url "http://weblate.org/graphics/weblate-32.png"
  maintained_by :github => 'nijel'

  def receive_push
    url = data['url']
    url.gsub! /\s/, ''

    if url.empty?
      raise_config_error "Invalid URL: #{url.inspect}"
    end

    if url !~ /^https?\:\/\//
      url = "http://#{url}"
    end

    res = http_post "#{url}/hooks/github/",
      :payload => generate_json(payload)

    if res.status < 200 || res.status > 299
      raise_config_error "Failed with #{res.status}"
    end
  rescue URI::InvalidURIError
    raise_config_error "Invalid URL: #{data['url']}"
  end
end


