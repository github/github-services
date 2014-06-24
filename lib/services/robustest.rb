class Service::RobusTest < Service
  default_events :issues, :issue_comment, :push
  string :project_key
  white_list :project_key

  url "http://www.robustest.com"
  logo_url "http://www.robustest.com/img/logo.png"
  maintained_by :github => 'omnarayan'
  # Support channels for user-level Hook problems (service failure,
  # misconfigured
  supported_by :web => 'http://robustest.com/',
    :email => 'care@robustest.com'

  def receive_push
    payload['commits'].each do |commit|
      message = commit['message'].clone
      while !(id= message[/#(\d)+/]).nil? do
        message.gsub!(id,'')
        issue_no = id.gsub('#','')
        changeset = { :message => commit['message'] }
        changeset[:gitsha]   = commit['id']
        changeset[:added]    = commit['added'].map    { |f| ['A', f] }
        changeset[:removed]  = commit['removed'].map  { |f| ['R', f] }
        changeset[:modified] = commit['modified'].map { |f| ['M', f] }
        changeset[:timestamp] = Date.parse(commit['timestamp'])
        changeset[:name] = commit['author']['name']
        changeset[:email]= commit['author']['email']
        begin
          http.headers['Content-Type'] = 'application/json'
          res = http_post 'http://www.robustest.com/project/%s/integration/git/%s' % [data['project_key'],  issue_no],
            generate_json(changeset)
        rescue URI::InvalidURIError
          raise_config_error "Invalid project: #{data['project_key']}"
        end
      end
    end
  end
end
