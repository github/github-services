class Service::Bugly < Service
  string :project_id, :account_name, :token

  def receive_push
    http_post "http://#{data['account_name']}.bug.ly/changesets.json",
      JSON.generate(payload),
      'X-BuglyToken' => data['token'],
      'Content-Type' => 'application/json'
    return
    query_string = "?service=github&project_id=#{data['project_id']}"
    url = URI.parse("#{account}/changesets.json#{query_string}")
    req = Net::HTTP::Post.new(url.request_uri)
    req.body = JSON.generate(payload)
    req.initialize_http_header({"X-BuglyToken" => data['token']})
    req.set_content_type('application/json')
    Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
  end
end
