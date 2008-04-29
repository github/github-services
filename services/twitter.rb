service :twitter do |data, payload|
  twitter    = Twitter::Base.new(data['username'], data['password'])
  repository = payload['repository']['name']

  payload['commits'].each do |commit|
    commit = commit.last
    begin
      Timeout::timeout(2) do
        url = Net::HTTP.get "tinyurl.com", "/api-create.php?url=#{commit['url']}"
      end
    rescue
    end
    url ||= commit['url']
    twitter.post "[#{repository}] #{url} #{commit['author']['name']} - #{commit['message']}"
  end
end
