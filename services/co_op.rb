service :co_op do |data, payload|
  co_op_headers = {
    'Accept'        => 'application/json',
    'Content-Type'  => 'application/json; charset=utf-8',
    'User-Agent'    => 'GitHub Notifier'
  }
  co_op = Net::HTTP.new("coopapp.com", 80)
  begin
    repository = payload['repository']['name']
    payload['commits'].each do |commit|
      status = "#{commit['author']['name']} just committed a change to #{repository} on GitHub: #{commit['message']} (#{commit['url']})"
      co_op.post("/groups/#{data['group_id']}/notes", {:status => status, :key => data['token']}.to_json, co_op_headers)
    end
  rescue Net::HTTPBadResponse
    raise GitHub::ServiceConfigurationError, "Invalid configuration"
  end
end