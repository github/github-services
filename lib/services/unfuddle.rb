class Service::Unfuddle < Service
  string   :subdomain, :repo_id, :username
  password :password
  boolean  :httponly
  white_list :subdomain, :repo_id, :username

  def receive_push
    u_repoid    = data['repo_id'].to_i
    repository  = payload['repository']['name']
    branch      = branch_name
    before      = payload['before']
    # use https by default since most accounts support SSL
    protocol    = data['httponly'].to_i == 1 ? 'http' : 'https'

    http.url_prefix = "#{protocol}://#{data['subdomain']}.unfuddle.com"
    http.basic_auth data['username'], data['password']

    # grab people data for matching author-id
    begin
      res = http_get "/api/v1/people.json"
      if res.status < 200 || res.status > 299
        raise_config_error
      end

      people = JSON.parse(res.body)
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
           Net::ProtocolError => e
      raise_config_error "#{e.class}: #{e.message}"
    end

    payload['commits'].each do |commit|
      commit_id = commit['id']
      message   = "#{commit['message']}\n#{commit['url']}"
      files     = commit['removed'] | commit['added'] | commit['modified']

      # set Unfuddles's correct changeset association by getting the matching
      # author-id
      author_id = 0
      people.each do |person|
        if person['email'] == commit['author']['email']
          author_id = person['account_id'].to_i
          break
        end
      end

      if author_id > 0
        author_id_element = "<author-id type=\"integer\">#{author_id}</author-id>"
        committer_id_element = "<committer-id type=\"integer\">#{author_id}</committer-id>"
      else
        author_id_element = ""
        committer_id_element = ""
      end

      changeset_xml = <<-XML.strip
        <changeset>
          #{author_id_element}
          <author-name>#{CGI.escapeHTML(commit['author']['name'])}</author-name>
          <author-email>#{CGI.escapeHTML(commit['author']['email'])}</author-email>
          <author-date type="datetime">#{CGI.escapeHTML(commit['timestamp'])}</author-date>
          #{committer_id_element}
          <committer-name>#{CGI.escapeHTML(commit['author']['name'])}</committer-name>
          <committer-email>#{CGI.escapeHTML(commit['author']['email'])}</committer-email>
          <committer-date type="datetime">#{CGI.escapeHTML(commit['timestamp'])}</committer-date>
          <created-at type="datetime">#{CGI.escapeHTML(commit['timestamp'])}</created-at>
          <message>#{CGI.escapeHTML(message)}</message>
          <revision>#{CGI.escapeHTML(commit_id)}</revision>
        </changeset>
      XML

      begin
        res = http_post "/api/v1/repositories/#{u_repoid}/changesets.json?process_message_actions=true" do |req|
          req.headers['Content-Type'] = 'application/xml'
          req.body = changeset_xml
        end
      end
    end
  end
end
