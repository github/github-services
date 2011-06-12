class Service::YouTrack < Service
  def receive_push
    http.url_prefix = data['base_url']
    payload['commits'].each { |c| process_commit(c) }
  end

  def login
    @logged_in ||= begin
      res = http_post 'rest/user/login' do |req|
        req.params.update \
          :login => data['username'],
          :password => data['password']
        req.headers['Content-Length'] = '0'
      end
      verify_response(res)

      http.headers['Cookie'] = res.headers['set-cookie']
      http.headers['Cache-Control'] = 'no-cache'
      true
    end
  end

  def process_commit(commit)
    author = nil
    commit["message"].each{ |commit_line|
      issue_id = commit_line[/( |^)#(\w+-\d+) /, 2]
      next if issue_id.nil?

      # lazily load author
      author ||= find_user_by_email(commit["author"]["email"])
      return if author.nil?

      command = commit_line[/( |^)#\w+-\d+ (.+)/, 2].strip
      command = "Fixed" if command.nil?
      execute_command(author, issue_id, command)
    }
  end

  def find_user_by_email(email)
    login
    counter = 0
    found_user = nil
    while true
      body = ""
      res = http_get "rest/admin/user", :q => email, :group => data['committers'], :start => counter
      verify_response(res)
      xml_body = REXML::Document.new(res.body)
      xml_body.root.each_element do |user_ref|
        res = http_get "rest/admin/user/#{user_ref.attributes['login']}"
        verify_response(res)
        if REXML::Document.new(res.body).root.attributes["email"].upcase == email.upcase
          return if !found_user.nil?
          found_user = user_ref.attributes["login"]
        end
      end
      return found_user if xml_body.root.elements.size < 10
      counter += 10
    end
  end

  def execute_command(author, issue_id, command)
    res = http_post "rest/issue/#{issue_id}/execute" do |req|
      req.params[:command] = command
      req.params[:runAs]   = author
    end
    verify_response(res)
  end

  def verify_response(res)
    case res.status
      when 200..299
      when 403, 401, 422 then raise_config_error("Invalid Credentials")
      when 404, 301, 302 then raise_config_error("Invalid YouTrack URL")
      else raise_config_error("HTTP: #{res.status}")
    end
  end
end
