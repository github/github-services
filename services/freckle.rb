service :freckle do |data, payload|

  entries, subdomain, token, project =
    [], data['subdomain'].strip, data['token'].strip, data['project'].strip

  payload['commits'].each do |commit|
    minutes = (commit["message"].split(/\s/).find { |item| /^f:/ =~ item } || '')[2,100]
    next unless minutes
    entries << {
      :date => commit["timestamp"],
      :minutes => minutes,
      :description => commit["message"].gsub(/(\s|^)f:.*(\s|$)/, '').strip,
      :url => commit['url'],
      :project_name => project,
      :user => commit['author']['email']
    }
  end
  uri = URI.parse("http://#{data['subdomain']}.letsfreckle.com/api/entries/import")
  req = Net::HTTP::Post.new(uri.path)
  req.set_content_type('application/json')
  req.body = { :entries => entries, :token => data['token'] }.to_json
  Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req) }
end
