service :presently do |data, payload|
  repository = payload['repository']['name']
  url = URI.parse("https://#{data['subdomain']}.presentlyapp.com/api/twitter/statuses/update.xml")

  receiver = (data['group'].nil? || data['group'] == '') ? 'system' : data['group']
  
  payload['commits'].each do |commit|
    
    status = "b #{receiver} [#{repository}] #{commit['author']['name']} - #{commit['message']}"
    status = status[0...137] + '...' if status.length > 140
    
    paste = "\"Commit #{commit['id']}\":#{commit['url']}\n\n"
    paste << "#{commit['message']}\n\n"
    
    %w(added modified removed).each do |kind|
      commit[kind].each do |filename|
        paste << "* #{kind.capitalize} '#{filename}'\n"
      end
    end
    
    req = Net::HTTP::Post.new(url.path)
    req.basic_auth(data['username'], data['password'])
    req.set_form_data(
      'status' => status, 
      'source' => 'GitHub', 
      'paste_format' => 'textile',
      'paste_text' => paste
    )

    Net::HTTP.new(url.host, url.port).start { |http| http.request(req) }
  end
end
