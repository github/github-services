service :socialcast do |data, payload|
  repository  = payload['repository']['name']
  url         = URI.parse("https://#{data['api_domain']}/api/messages.xml")
  group_id    = (data['group_id'].nil? || data['group_id'] == '') ? '' : data['group_id'] 
  kind_symbol = Hash["added" => "+", "modified" => "Δ", "removed" => "-"]
  s_if_plural = (payload['commits'].length > 1) ? 's' : ''
  title       = "#{payload['commits'].length} commit#{s_if_plural} pushed to Github repo [#{repository}]"
  message     = ""

  payload['commits'].each_with_index do |commit, i|
    timestamp = Date.parse(commit['timestamp'])
    heading = "√#{i+1} by #{commit['author']['name']} at #{timestamp}"
    message << "#{heading}\n"
    heading.length.times do
      message << "-"
    end
    message << "\n#{commit['url']}\n#{commit['message']}\n"

    %w(added modified removed).each do |kind|
      commit[kind].each do |filename|
        message << "#{kind_symbol[kind]} '#{filename}'\n"
      end
    end

    message << "\n"
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
