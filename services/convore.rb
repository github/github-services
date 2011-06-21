class Service::Convore < Service
  string :topic, :username
  password :password

  def receive_push
    raise_config_error "Missing username" if data['username'].to_s == ''

    repository  = payload['repository']['name']
    owner       = payload['repository']['owner']['name']
    branch      = payload['ref_name']
    commits     = payload['commits']
    compare_url = payload['compare']
    commits.reject! { |commit| commit['message'].to_s.strip == '' }
    return if commits.empty?

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

    http.url_prefix = "https://convore.com/api/topics"
    http.basic_auth data['username'], data['password']

    begin
      messages.each do |line|
        res = speak(data['topic_id'], line)
        if res.status < 200 or res.status > 299
          raise_config_error "Convore Error"
        end

        body = JSON.parse(res.body)
        raise_config_error "Convore Error" if body.include?("error")
      end

    rescue Faraday::Error::ConnectionFailed
      raise_config_error "Connection refused. Invalid group."
    end
  end

  def speak(topic_id, line)
    http_post "#{data['topic_id']}/messages/create.json",
      :message => line
  end
end
