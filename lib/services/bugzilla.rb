class Service::Bugzilla < Service
  string   :server_url, :username, :integration_branch
  password :password
  boolean  :central_repository
  white_list :server_url, :username, :integration_branch

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

    # Don't operate on these commits unless this is our "integration" (i.e. main) branch,
    # as defined by the user. If no integration_branch is set, we operate on all commits.
    return unless integration_branch?

    # Post comments on all bugs identified in commits
    repository = payload['repository']['url'].to_s
    commits = payload['commits'].collect{|c| Commit.new(c)}
    bug_commits = sort_commits(commits)
    bugs_to_close = []
    bug_commits.each_pair do | bug, commits |
      if data['central_repository']
        # Only include first line of message if commit already mentioned
        commit_messages = commits.collect{|c| c.comment(bug_mentions_commit?(bug, c))}
      else
        # Don't include commits already mentioned
        commit_messages = commits.select{|c| !bug_mentions_commit?(bug, c)}.collect{|c| c.comment}
      end
      post_bug_comment(bug, repository, commit_messages, branch.to_s)
      if commits.collect{|c| c.closes}.any?
        bugs_to_close << bug
      end
    end

    # Close bugs
    if data['central_repository']
      close_bugs(bugs_to_close)
    end
  end

  # Name of the branch for this payload; nil if it isn't branch-related.
  def branch
    return @branch if defined?(@branch)

    matches = payload['ref'].match(/^refs\/heads\/(.*)$/)
    @branch = matches ? matches[1] : nil
  end

  def integration_branch?
    data['integration_branch'].to_s.empty? or data['integration_branch'].to_s == branch.to_s
  end

  attr_writer :xmlrpc_client # Can define own server for testing
  def xmlrpc_client
    # XMLRPC client to communicate with Bugzilla server
    @xmlrpc_client ||= begin
      client = XMLRPC::Client.new2("#{data['server_url'].to_s}/xmlrpc.cgi")
      result = client.call('User.login', {'login' => data['username'].to_s, 'password' => data['password'].to_s})
      @token = result['token']
      client
    rescue XMLRPC::FaultException
      raise_config_error "Invalid login details"
    rescue SocketError, RuntimeError
      raise_config_error "Invalid server url"
    end
  end

  def xmlrpc_authed_call(method, args)
    # Add token parameter to XMLRPC call if one was received when logging into Bugzilla
    args['Bugzilla_token'] = @token if not @token.nil?
    xmlrpc_client.call(method, args)
  end

  def sort_commits(commits)
    # Sort commits into a hash of arrays based on bug id
    bug_commits = Hash.new{|k,v| k[v] = []}
    commits.each do |commit|
      commit.bugs.each do |bug|
        bug_commits[bug] << commit
      end
    end
    return bug_commits
  end

  def bug_mentions_commit?(bug_id, commit)
    # Check if a bug already mentions a commit.
    # This is to avoid repeating commits that have
    # been pushed to another person's repository
    result = xmlrpc_authed_call('Bug.comments', {'ids' => [bug_id]})
    all_comments = result['bugs']["#{bug_id}"]['comments'].collect{|c| c['text']}.join("\n")
    all_comments.include? commit.id
  rescue XMLRPC::FaultException, RuntimeError
    # Bug doesn't exist or Bugzilla version doesn't support getting comments
    false
  end

  def post_bug_comment(bug, repository, commit_messages, branch_name)
    # Post a comment on an individual bug
    if commit_messages.length == 0
      return
    end
    branch_str = branch_name.empty? ? "" : "#{branch_name} at "
    if commit_messages.length > 1
      message = "Commits pushed to #{branch_str}#{repository}\n\n"
    else
      message = "Commit pushed to #{branch_str}#{repository}\n\n"
    end
    message += commit_messages.join("\n\n")
    begin
      xmlrpc_authed_call('Bug.add_comment', {'id' => bug, 'comment' => message})
    rescue XMLRPC::FaultException
      # Bug doesn't exist or user can't add comments, do nothing
    rescue RuntimeError
      raise_config_error "Bugzilla version doesn't support adding comments"
    end
  end

  def close_bugs(bug_ids)
    if bug_ids.length > 0
      begin
        xmlrpc_authed_call('Bug.update', {'ids' => bug_ids, 'status' => 'RESOLVED', 'resolution' => 'FIXED'})
      rescue XMLRPC::FaultException, RuntimeError
        # Bug doesn't exist, user can't close bug, or version < 4.0 that doesn't support Bug.update.
        # Do nothing
      end
    end
  end

  class Commit
    attr_reader :closes, :bugs, :url, :id

    def initialize(commit_hash)
      @id = commit_hash['id'].to_s
      @url = commit_hash['url'].to_s
      @message = commit_hash['message'].to_s
      @closes = false

      # Get the list of bugs mentioned in this commit message
      message_re = /((close|fix|address)e?(s|d)? )?(ticket|bug|tracker item|issue)s?:? *([\d ,\+&#and]+)/i
      if (@message =~ message_re) != nil
        if $1
          @closes = true
        end
        @bugs = $5.split(/[^\d]+/).select{|b| !b.empty?}.collect{|b| Integer(b)}
      else
        @bugs = []
      end
    end

    def comment(first_line_only=false)
      # Comment contents for a commit
      output = "#{@url}\n"
      if first_line_only
        output += @message.lines.first.strip
      else
        output += @message.strip
      end
      return output
    end
  end
end
