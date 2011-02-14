service :convore do |data, payload|
  # fail fast with no username
  raise GitHub::ServiceConfigurationError, "Missing username" if data['username'].to_s == ''

  repository  = payload['repository']['name']
  owner       = payload['repository']['owner']['name']
  branch      = payload['ref_name']
  commits     = payload['commits']
  compare_url = payload['compare']
  commits.reject! { |commit| commit['message'].to_s.strip == '' }
  next if commits.empty?

  prefix = "[#{repository}/#{branch}]"
  primary, others = commits[0..4], Array(commits[5..-1])
  messages =
    primary.map do |commit|
      short = commit['message'].split("\n", 2).first
      short += ' ...' if short != commit['message']
      "#{prefix} #{short} - #{commit['author']['name']}"
    end

  if messages.size > 1
    before, after = payload['before'][0..6], payload['after'][0..6]
    url = compare_url
    summary =
      if others.any?
        "#{prefix} (+#{others.length} more) commits #{before}...#{after}: #{url}"
      else
        "#{prefix} commits #{before}...#{after}: #{url}"
      end
    messages << summary
  else
    url = commits.first['url']
    messages[0] = "#{messages.first} (#{url})"
  end

  def speak(data, line)
    url = URI.parse("https://convore.com/api/topics/#{data['topic_id']}/messages/create.json")
    http = Net::HTTP.new(url.host, 443)
    req = Net::HTTP::Post.new(url.path)
    http.use_ssl = true
    req['Content-Type'] = "application/json"
    req.basic_auth data['username'], data['password']
    req.set_form_data({ 'message' => line })
    return http.request(req)
  end
  
  begin
    messages.each do |line| 
      
      response = speak(data, line)
      
      case response
        when Net::HTTPSuccess
          # OK
        else
          response.error!
        end
      
    end

  rescue Errno::ECONNREFUSED => boom
    raise GitHub::ServiceConfigurationError, "Connection refused. Invalid group."
  end
end