class Service::Lighthouse < Service
  string  :subdomain, :project_id
  password :token
  boolean :private, :send_only_ticket_commits
  white_list :subdomain, :project_id

  def receive_push
    # matches string with square braces with content starting with # and a digit.
    check_for_lighthouse_flags = /\[#\d.+?\]/

    payload['commits'].each do |commit|
      next if commit['message'] =~ /^x /
      next if data['send_only_ticket_commits'] == '1' \
        && (commit['message'] =~ check_for_lighthouse_flags).nil?

      commit_id = commit['id']
      added     = commit['added'].map    { |f| ['A', f] }
      removed   = commit['removed'].map  { |f| ['R', f] }
      modified  = commit['modified'].map { |f| ['M', f] }
      diff      = YAML.dump(added + removed + modified)

      diff = YAML.dump([]) if data['private']

      title = "Changeset [%s] by %s" % [commit_id, commit['author']['name']]
      body  = "#{commit['message']}\n#{commit['url']}"
      changeset_xml = <<-XML.strip
        <changeset>
          <title>#{CGI.escapeHTML(title)}</title>
          <body>#{CGI.escapeHTML(body)}</body>
          <changes type="yaml">#{CGI.escapeHTML(diff)}</changes>
          <committer>#{CGI.escapeHTML(commit['author']['name'])}</committer>
          <revision>#{CGI.escapeHTML(commit_id)}</revision>
          <changed-at type="datetime">#{CGI.escapeHTML(commit['timestamp'])}</changed-at>
        </changeset>
      XML

      @lighthouse_body = changeset_xml

      account = "http://#{data['subdomain']}.lighthouseapp.com"

      begin
        http.basic_auth data['token'], 'x'
        http.headers['Content-Type'] = 'application/xml'
        http_post '%s/projects/%d/changesets.xml' % [
          "http://#{data['subdomain']}.lighthouseapp.com", data['project_id'].to_i],
          changeset_xml
      rescue URI::InvalidURIError
        raise_config_error "Invalid subdomain: #{data['subdomain']}"
      end
    end
  end

  def reportable_http_env(env, time)
    hash = super(env, time)
    hash[:request][:body] = @lighthouse_body
    @lighthouse_body = nil
    hash
  end
end
