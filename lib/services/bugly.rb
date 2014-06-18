class Service::Bugly < Service
  string :project_id, :account_name
  password :token
  white_list :project_id, :account_name

  def receive_push
    http.ssl[:verify] = false # :(
    http_post "https://#{data['account_name']}.bug.ly/changesets.json?service=github&project_id=#{data['project_id']}",
      generate_json(payload),
      'X-BuglyToken' => data['token'],
      'Content-Type' => 'application/json'
    return
  end
end
