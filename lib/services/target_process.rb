class Service::TargetProcess < Service
  string    :base_url, :username
  password  :password
  white_list :base_url, :username

  def receive_push
    # setup things for our REST calls
    http.ssl[:verify] = false
    http.url_prefix = data['base_url']
    http.headers['Content-Type'] = 'application/json'
    http.basic_auth(data['username'], data['password'])
    @project_id = data['project_id']
    # And go!
    payload["commits"].each{
        |commit| process_commit(commit)
    }
  end

private
  def valid_response?(res)
    case res.status
      when 200..299
      when 403, 401, 422 then raise_config_error("Invalid Credentials")
      when 404, 301, 302 then raise_config_error("Invalid TargetProcess URL")
      else raise_config_error("HTTP: #{res.status}")
    end
    true
  end

  def process_commit(commit)
    author = commit["author"]["email"]    
    commit_url = commit["url"]
    commit["message"].split("\n").each { |commit_line|
      parts = commit_line.match(/(\s|^)(?#|id:)(\d+)(:[^\s]+)?(\s|$)/)
      next if parts.nil?
      entity_id = parts[3].strip
      next if entity_id.nil? or entity_id.length == 0
      if parts[4].nil? or parts[4].length == 0
          command = nil
      else
          command = parts[4].strip
      end
      execute_command(author, entity_id, command, commit_line, commit_url, commit)
    }
  end

  def execute_command(author, entity_id, new_state, commit_message, commit_url, raw_commit)
    return if command.nil?
    require 'json'
    # get the user's id
    res = http_get "api/v1/Users", {:where => "(Email eq '%s')" % author}
    valid_response?(res)
    author_id = begin JSON.parse(res.body)['Users']['User']['Id'] rescue nil end
    return if author_id.nil?
    # Make it happen
    commit_message = "#{commit_message}<br />Commit: #{commit_url}"
    valid_response?(http_post "api/v1/Comments", "{General: {Id: #{entity_id}}, Description: '#{commit_message.gsub("'","\'")}', Owner: {Id: #{author_id}}}")
    if !new_state.nil?
      valid_response?(http_post "api/v1/Assignables/%s" % entity_id, "{EntityState: {Name: #{new_state}}}")
    end
  end
end

