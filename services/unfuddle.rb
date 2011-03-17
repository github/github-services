# I'm not a ruby expert, so please pardon the mess.
# Author: Clay Loveless <clay@jexy.co>

service :unfuddle do |data, payload|

  u_repoid    = data['u_repoid']
  u_account   = "http://#{data['subdomain']}.unfuddle.com/"

  repository  = payload['repository']['name']
  branch      = payload['ref_name']
  before      = payload['before']
  
  # setup
  uri = URI.parse(u_account)
  http = Net::HTTP.new(uri.host, uri.port)
  
  # grab people data for matching author-id
  begin
    req = Net::HTTP::Get.new('/api/v1/people.json')
    req.basic_auth data['username'], data['password']
    response = http.request(req)
    people = JSON.parse(response.body)
  rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
         Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
         puts e.message
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
      url = URI.parse("%s/api/v1/repositories/%d/changesets.json" % [u_account, u_repoid.to_i])
      req = Net::HTTP::Post.new(url.path)
      req.basic_auth data['username'], data['password']
      req.body = changeset_xml
      req.set_content_type('application/xml')
      http = Net::HTTP.new(url.host, url.port)
      http.set_debug_output($stdout)
      http.start do |http|
        # send the changeset
        response = http.request(req)
        # process message actions requires a separate request
        changeset_url = URI.parse(response['location'])
        changeset_req = Net::HTTP::Put.new("#{changeset_url.path}/process_message_actions.json")
        changeset_req.basic_auth data['username'], data['password']
        changeset_req.body = "<request><process-message-actions>true</process-message-actions></request>"
        changeset_req.set_content_type('application/xml')
        changeset_response = http.request(changeset_req)
        # someday ... push files and diffs!
      end
    rescue URI::InvalidURIError
      raise GitHub::ServiceConfigurationError, "Invalid Unfuddle repository id: #{data['u_repoid']}"
    end
    
  end

end