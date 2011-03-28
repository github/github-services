service :socialcast do |data, payload|
  repository = payload['repository']['name']
  url = URI.parse("https://#{data['api_domain']}/api/messages.xml")
  group_id = (data['group_id'].nil? || data['group_id'] == '') ? '' : data['group_id']
  
  payload['commits'].each do |commit|
    
    title = "Github commit to repo [#{repository}] by #{commit['author']['name']}"
    message = "#{commit['url']}\n#{commit['message']}\n"
    
    %w(added modified removed).each do |kind|
      commit[kind].each do |filename|
        message << "* #{kind.capitalize} '#{filename}'\n"
      end
    end
    
    req = Net::HTTP::Post.new(url.path)
    req.basic_auth(data['username'], data['password'])
    req.set_form_data(
      'message[title]' => title,
      'message[body]' => message, 
      'message[group_id]' => group_id
    )

    net = Net::HTTP.new(url.host, 443)
    net.use_ssl = true
    net.start { |http| http.request(req) }
  end
end
