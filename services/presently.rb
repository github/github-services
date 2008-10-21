service :presently do |data, payload|
  repository = payload['repository']['name']
  url = URI.parse("https://#{data['subdomain']}.presentlyapp.com/api/twitter/statuses/update.xml")

  prefix = (data['group_name'].nil? || data['group_name'] == '') ? '' : "b #{data['group_name']} "
  
  payload['commits'].each do |commit|
    
    status = "#{prefix}[#{repository}] #{commit['author']['name']} - #{commit['message']}"
    status = status[0...137] + '...' if status.length > 140
    
    paste = "\"Commit #{commit['id']}\":#{commit['url']}\n\n"
    paste << "#{commit['message']}\n\n"
    
    %w(added modified removed).each do |kind|
      commit[kind].each do |filename|
        paste << "* *#{kind.capitalize}* '#{filename}'\n"
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

    net = Net::HTTP.new(url.host, 443)
    net.use_ssl = true
    net.start { |http| http.request(req) }
  end
end
