service :talker do |data, payload|
  repository = payload['repository']['name']
  branch = payload['ref'].split('/').last
  commits = payload['commits']
  token = data['token']
  url = URI.parse("#{data['url']}/messages.json")

  if data['digest'] == 1
    commit = commits.last
    message = "[#{repository}/#{branch}] #{commit['message']} (+#{commits.size - 1} more commits...) - #{commit['author']['name']} (#{commit['url']}))"
    
    req = Net::HTTP::Post.new(url.path)
    req["X-Talker-Token"] = "#{token}"
    req.set_form_data('message' => message)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true if url.port == 443 || url.instance_of?(URI::HTTPS)
    http.start { |http| http.request(req) }
  else
    commits.each do |commit|
      message = "[#{repository}/#{branch}] #{commit['message']} - #{commit['author']['name']} (#{commit['url']})"
      
      req = Net::HTTP::Post.new(url.path)
      req["X-Talker-Token"] = "#{token}"
      req.set_form_data('message' => message)

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true if url.port == 443 || url.instance_of?(URI::HTTPS)
      http.start { |http| http.request(req) }
    end
  end
end
