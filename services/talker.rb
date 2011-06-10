service :talker do |data, payload|
  repository = payload['repository']['name']
  branch = payload['ref_name']
  commits = payload['commits']
  token = data['token']
  url = URI.parse("#{data['url']}/messages.json")

  if data['digest'] == 1
    commit = commits.last
    messages = ["#{commit['author']['name']} pushed #{commits.size} commits to [#{repository}/#{branch}] #{payload['compare']}"]
  else
    messages = commits.collect do |commit|
      "#{commit['author']['name']} pushed \"#{commit['message'].split("\n").first}\" -  #{commit['url']} on [#{repository}/#{branch}]"
    end
  end

  messages.each do |message|
    req = Net::HTTP::Post.new(url.path)
    req["X-Talker-Token"] = "#{token}"
    req.set_form_data('message' => message)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true if url.port == 443 || url.instance_of?(URI::HTTPS)
    http.start { |http| http.request(req) }
  end
end
