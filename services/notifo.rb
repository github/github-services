service :notifo do |data, payload|
  
  repository = payload['repository']['name']
  url = URI.parse('https://api.notifo.com/v1/send_notification')

  payload['commits'].each do |commit|
    req = Net::HTTP::Post.new(url.path)
    req.basic_auth(data['username'], data['apisecret'])
    req.set_form_data(
      'to' => data['username'],
      'msg' => URI.escape("#{commit['author']['name']} - #{commit['message']}", Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")),
      'label' => 'GitHub Commit', 
      'title' => URI.escape("#{repository}", Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")), 
      'uri' => URI.escape(commit['url'], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    )

    net = Net::HTTP.new(url.host, 443) 
    net.use_ssl = true
    net.verify_mode = OpenSSL::SSL::VERIFY_NONE
    net.start { |http| http.request(req) }
  end
end
