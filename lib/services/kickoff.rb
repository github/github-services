class Service::Kickoff < Service
  string :project_id
  password :project_token
  white_list :project_id

  def receive_push
    raise_config_error 'Missing project id' if data['project_id'].to_s.empty?
    raise_config_error 'Missing project token' if data['project_token'].to_s.empty?

    messages = []
    messages << "#{summary_message}: #{summary_url}"
    messages += commit_messages.first(8)

    if messages.first =~ /pushed 1 new commit/
      messages.shift # drop summary message
      messages.first << " (#{distinct_commits.first['url']})"
    end

    doc = REXML::Document.new("<request></request>")
    e = REXML::Element.new("message")
    e.text = messages.join("\n")
    doc.root.add(e)
    e = REXML::Element.new("service")
    e.text = "github"
    doc.root.add(e)

    http_post "http://api.kickoffapp.com/projects/#{data['project_id']}/chat" do |req|
      req.params[:token] = data['project_token']
      req.body = doc.to_s
    end
  end
end
