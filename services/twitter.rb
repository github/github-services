service :twitter do |data, payload|
  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  twitter    = Twitter::Base.new(data['username'], data['password'])
  begin
    Timeout::timeout(2) do
      url = Net::HTTP.get "tinyurl.com", "/api-create.php?url=#{commit['url']}"
    end
  rescue
  end
  url ||= commit['url']

  payload['commits'].each do |commit|
    commit = commit.last
    text   = "[#{repository}] #{url} #{commit['author']['name']} - #{commit['message']}"
    twitter.post text
  end
end
