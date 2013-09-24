class Service::YouTrack < Service
  string :base_url, :committers, :username, :branch
  password :password
  white_list :base_url, :username, :committers, :branch

  url 'http://http://www.jetbrains.com/youtrack'
  logo_url 'http://www.jetbrains.com/img/logos/YouTrack_logo_press_materials.gif'

  maintained_by :github => 'anna239'
  supported_by :web => 'http://www.jetbrains.com/support/youtrack',
               :email => 'youtrack-feedback@jetbrains.com',
               :twitter => 'youtrack'


  def receive_push
    # If branch is defined by user setting, process commands only if commits
    # are on that branch. If branch is not defined, process regardless of branch.
    return unless active_branch?

    http.ssl[:verify] = false
    http.url_prefix = data['base_url']
    payload['commits'].each { |c| process_commit(c) }
  end

  def active_branch?
    pushed_branch = payload['ref'].to_s[/refs\/heads\/(.*)/, 1]
    active_branch = data['branch'].to_s
    active_branch.empty? or active_branch.split(' ').include?(pushed_branch)
  end

  def login
    @logged_in ||= begin
      api_key = data['api_key']
      if api_key.nil?
        res = http_post 'rest/user/login' do |req|
          req.params.update \
          :login => data['username'],
          :password => data['password']
          req.headers['Content-Length'] = '0'
        end
        verify_response(res)

        http.headers['Cookie'] = res.headers['set-cookie']
      else
        http.headers['X-YouTrack-ApiKey'] = api_key
      end
      http.headers['Cache-Control'] = 'no-cache'
      true
    end
  end

  def process_commit(commit)
    author = nil
    commit['message'].split("\n").each { |commit_line|
      issue_id = commit_line[/( |^)#(\w+-\d+)\b/, 2]
      next if issue_id.nil?

      login
      # lazily load author
      author ||= find_user_by_email(commit['author']['email'])
      return if author.nil?

      command = commit_line[/( |^)#\w+-\d+ (.+)/, 2]
      command = 'Fixed' if command.nil?
      command.strip!
      comment_string = "Commit made by '''" + commit['author']['name'] + "''' on ''" + commit['timestamp'] + "''\n" + commit['url'] + "\n\n{quote}" + commit['message'].to_s + '{quote}'
      execute_command(author, issue_id, command, comment_string)
    }
  end

  def find_user_by_email(email)
    counter = 0
    found_user = nil
    while true
      body = ''
      res = http_get 'rest/admin/user', :q => email, :group => data['committers'], :start => counter
      verify_response(res)
      xml_body = REXML::Document.new(res.body)
      xml_body.root.each_element do |user_ref|
        res = http_get "rest/admin/user/#{user_ref.attributes['login']}"
        verify_response(res)
        attributes = REXML::Document.new(res.body).root.attributes
        if attributes['email'].upcase == email.upcase || (attributes['jabber'] ? attributes['jabber'].upcase == email.upcase : false)
          return if !found_user.nil?
          found_user = user_ref.attributes['login']
        end
      end
      return found_user if xml_body.root.elements.size < 10
      counter += 10
    end
  end

  def execute_command(author, issue_id, command, comment_string)
    res = http_post "rest/issue/#{issue_id}/execute" do |req|
      req.params[:command] = command
      req.params[:comment] = comment_string
      req.params[:runAs] = author
    end
    verify_response(res)
  end

  def verify_response(res)
    case res.status
      when 200..299
      when 403, 401, 422 then
        raise_config_error('Invalid Credentials')
      when 404, 301, 302 then
        raise_config_error('Invalid YouTrack URL')
      else
        raise_config_error("HTTP: #{res.status}")
    end
  end
end
