class Service::RationalJazzHub < Service::HttpPost
  string   :username
  password :password
  string :override_server_url
  white_list :username

  def receive_push
    http.builder.response :logger
    username = required_config_value('username')
    password = required_config_value('password')
    override_server_url = data['override_server_url']
    server_url = override_server_url || "https://hub.jazz.net/manage"
    post_url = "#{server_url}/processGitHubPayload?jazzhubUsername=#{username}&jazzhubPassword=#{password}"
    deliver post_url
  end
end
