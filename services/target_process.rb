class Service::TargetProcess < Service
  string    :base_url, :username, :project_id
  password  :password
  white_list :base_url, :username, :project_id

  def receive_push
    # setup things for our REST calls
    http.ssl[:verify] = false
    http.url_prefix = data['base_url']
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
      parts = commit_line.match(/(\s|^)#(\d+)(:[^\s]+)?(\s|$)/)
      next if parts.nil?
      entity_id = parts[2].strip
      next if entity_id.nil? or entity_id.length == 0
      if parts[3].nil? or parts[3].length == 0
          command = nil
      else
          command = parts[3].strip
      end
      execute_command(author, entity_id, command, commit_line, commit_url)
    }
  end

  def execute_command(author, entity_id, command, commit_message, commit_url)
    return if command.nil?
    # get the user's id
    res = http_get "api/v1/Users", {:where => "(Email eq '%s')" % author}
    valid_response?(res)
    author_id = begin Hash.from_xml(res.body)['Users']['User']['Id'] rescue nil end
    return if author_id.nil?
    # get Context data for our project
    res = http_get "api/v1/Context", :ids => @project_id
    valid_response?(res)
    context_data = Hash.from_xml res.body
    acid = context_data['Context']['Acid']
    # get the assignable's type
    res = http_get "api/v1/Assignables/%s" % entity_id, {:include => '[EntityType]', :acid => acid}
    valid_response?(res)
    assignable = Hash.from_xml res.body
    return if assignable.nil?
    entity_type = assignable['Assignable']['EntityType']['Name']
    # Gather next state's ID
    res = http_get "api/v1/Processes/%s/EntityStates" % [context_data['Context']['Processes']['ProcessInfo']['Id']],
        {:where => "(Name eq '%s') and (EntityType.Name eq '%s')" % [command, entity_type], :acid => acid}
    valid_response?(res)
    new_state = begin Hash.from_xml(res.body)['EntityStates']['EntityState']['Id'] rescue nil end
    # Make it happen
    http.headers['Content-Type'] = 'application/json'
    commit_message = "#{commit_message}<br />Commit: #{commit_url}"
    valid_response?(http_post "api/v1/Comments", "{General: {Id: #{entity_id}}, Description: '#{commit_message.gsub("'","\'")}', Owner: {Id: #{author_id}}}")
    if !command.nil? and !new_state.nil?
      valid_response?(http_post "api/v1/%s" % ((entity_type == "UserStory") ? "UserStories" : entity_type+'s'), "{Id: #{entity_id}, EntityState: {Id: #{new_state}}}")
    end
  end
end

