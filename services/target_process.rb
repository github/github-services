class Service::TargetProcess < Service
  string    :base_url, :username, :project_id
  password  :password

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
    commit["message"].each { |commit_line|
      parts = commit_line.match(/(\s|^)#(\d+):?([^\s]+)?(.*)/)
      next if parts.nil?
      entity_id = parts[2].strip
      next if entity_id.nil? or entity_id.length == 0
      if parts[3].nil? or parts[3].length == 0
          command = nil
      else
          command = parts[3].strip
      end
      execute_command(author, entity_id, command, commit_line)
    }
  end

  def execute_command(author, entity_id, command, commit_message)
    # get the user's id
    res = http_get "api/v1/Users", :include => '[Email]'
    valid_response?(res)
    author_id = nil
    Hash.from_xml(res.body)['Items']['User'].each do |u|
      if u['Email'] == author
        author_id = u['Id']
        break
      end
    end
    return if author_id.nil?
    # get Context data for our project
    res = http_get "api/v1/Context", :ids => @project_id
    valid_response?(res)
    context_data = Hash.from_xml res.body
    acid = context_data['Context']['Acid']
    if !command.nil?
      # Gather the next state ID
      res = http_get "api/v1/Processes/%s/EntityStates" % [context_data['Context']['Processes']['ProcessInfo']['Id']],
          :acid => acid
      valid_response?(res)
      new_state = nil
      Hash.from_xml(res.body)['Items']['EntityState'].each do |s|
        if s['Name'] == command
          new_state = s['Id']
          break
        end
      end
      return if new_state.nil?
    end
    # get the assignable's type
    res = http_get "api/v1/Assignables/%s" % entity_id, {:include => '[EntityType]', :acid => acid}
    valid_response?(res)
    assignable = Hash.from_xml res.body
    return if assignable.nil?
    entity_type = assignable['Assignable']['EntityType']['Name']
    # Make it happen
    http.headers['Content-Type'] = 'application/json'
    valid_response?(http_post "api/v1/Comments", "{General: {Id: #{entity_id}}, Description: '#{commit_message}', Owner: {Id: #{author_id}}}")
    if !command.nil?
      case entity_type
      when "UserStory"
          call = "UserStories"
      when "Bug"
          call = "Bugs"
      when "Task"
          call = "Tasks"
      else
          return
      end
      valid_response?(http_post "api/v1/%s" % call, "{Id: #{entity_id}, EntityState: {Id: #{new_state}}}")
    end
  end
end

