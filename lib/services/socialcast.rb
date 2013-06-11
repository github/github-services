# encoding: utf-8
class Service::Socialcast < Service
  string   :api_domain, :group_id, :username
  password :password
  white_list :api_domain, :group_id, :username

  def receive_push
    repository  = payload['repository']['name']
    group_id    = (data['group_id'].nil? || data['group_id'] == '') ? '' : data['group_id']
    kind_symbol = Hash["added" => "+", "modified" => "Δ", "removed" => "-"]
    s_if_plural = (payload['commits'].length > 1) ? 's' : ''
    title       = "#{payload['commits'].length} commit#{s_if_plural} pushed to GitHub repo [#{repository}]"
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

    http.ssl[:verify] = false
    http.basic_auth(data['username'], data['password'])
    http_post "https://#{data['api_domain']}/api/messages.xml",
      'message[title]' => title,
      'message[body]' => message,
      'message[group_id]' => group_id
  end
end

