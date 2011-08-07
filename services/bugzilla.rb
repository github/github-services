class Service::Bugzilla < Service
  string :server_url, :username, :password

  def receive_push
    # Check for settings
    if data['server_url'].to_s.empty?
      raise_config_error "Bugzilla url not set"
    end
    if data['username'].to_s.empty?
      raise_config_error "username not set"
    end
    if data['password'].to_s.empty?
      raise_config_error "password not set"
    end
    post_comments(data, payload)
  end

  def post_comments(data, payload)
    # Post comments on all bugs identified in commits
    repository = payload['repository']['url'].to_s
    bug_commits = sort_commits(payload['commits'])
    bug_commits.each_pair do | bug, commits |
      begin
        xmlrpc_client.call('Bug.add_comment',{'id'=>bug,'comment'=>bug_comment(repository, commits)})
      rescue XMLRPC::FaultException
        # Bug doesn't exist or user can't add comments, do nothing
      end
    end
  end

  attr_writer :xmlrpc_client # Can define own server for testing
  def xmlrpc_client
    # XMLRPC client to communicate with Bugzilla server
    @xmlrpc_client ||= begin
      client = XMLRPC::Client.new2("#{data['server_url'].to_s}/xmlrpc.cgi")
      client.call('User.login',{'login'=> data['username'].to_s, 'password' => data['password'].to_s})
      client
    rescue XMLRPC::FaultException
      raise_config_error "Invalid login details"
    rescue SocketError, RuntimeError
      raise_config_error "Invalid server url"
    end
  end

  def sort_commits(commits)
    # Sort commits into a hash based on bug id
    bug_commits = Hash.new{|k,v| k[v] = []}
    commits.each do |commit|
      bugs = bug_ids(commit['message'].to_s)
      bugs.each do |bug|
        if !bug_mentions_commit?(bug, commit)
          bug_commits[bug] << commit
        end
      end
    end
    return bug_commits
  end

  def bug_mentions_commit?(bug_id, commit)
    # Check if a bug already mentions a commit.
    # This is to avoid repeating commits that have
    # been pushed to another person's repository
    result = xmlrpc_client.call('Bug.comments',{'ids'=>[bug_id]})
    all_comments = result['bugs']["#{bug_id}"]['comments'].collect{|c| c['text']}.join("\n")
    all_comments.include? commit['id'].to_s
  rescue XMLRPC::FaultException
    # Bug doesn't exist, might as well prevent it from being commented on here
    true
  end

  def bug_ids(message)
    # Get the list of bugs mentioned in this commit message
    message_re = /(ticket|bug|tracker item)s?:? *([\d ,\+&and]+)/i
    if (message =~ message_re) != nil
      bugs = $2.split(/[^\d]+/).collect{|b| Integer(b)}
    else
      bugs = []
    end
  end

  def bug_comment(repository, commits)
    # Comment to post on an individual bug
    if commits.length > 1
      message = "Commits pushed to #{repository}\n\n"
    else
      message = "Commit pushed to #{repository}\n\n"
    end
    message += commits.collect{|c| commit_comment(c)}.join("\n\n")
  end

  def commit_comment(commit)
    # Comment contents for each commit
    "#{commit['url']}\n" +
    "#{commit['message']}"
  end
end
