class Service::Presently < Service
  string   :subdomain, :group_name, :username
  password :password

  def receive_push
    repository = payload['repository']['name']

    # :(
    http.ssl[:verify] = false

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

      http.url_prefix = "https://#{data['subdomain']}.presently.com"
      http.basic_auth(data['username'], data['password'])
      http_post "/api/twitter/statuses/update.xml",
        'status' => status,
        'source' => 'GitHub',
        'paste_format' => 'textile',
        'paste_text' => paste
    end
  end
end
