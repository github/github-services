class Service::RationalJazzHub < Service::HttpPost
  string   :username
  password :password
  string :override_server_url
  white_list :username

  def receive_push
    username = required_config_value('username')
    password = required_config_value('password')
    override_server_url = data['override_server_url']
    server_url = (override_server_url.nil? || override_server_url.empty? ? "https://hub.jazz.net/manage" : override_server_url)
    post_url = "#{server_url}/processGitHubPayload?jazzhubUsername=#{username}&jazzhubPassword=#{password}"
    deliver post_url
  end
end
