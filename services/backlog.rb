class Service::Backlog < Service
  string   :api_url, :user_id
  password :password
  white_list :space_id, :user_id

  def receive_push
    if data['api_url'].to_s.empty?
      raise_config_error "Backlog API URL not set"
    end
    if data['user_id'].to_s.empty?
      raise_config_error "user_id not set"
    end
    if data['password'].to_s.empty?
      raise_config_error "password not set"
    end

    repository = payload['repository']['url'].to_s
    commits = payload['commits'].collect{|c| Commit.new(c)}
    issue_commits = sort_commits(commits)
    issue_commits.sort.map do | issue, commits |
      post(issue, repository, commits, branch.to_s)
    end

  end

  def branch
    return @branch if defined?(@branch)

    matches = payload['ref'].match(/^refs\/heads\/(.*)$/)
    @branch = matches ? matches[1] : nil
  end

  attr_writer :xmlrpc_client
  def xmlrpc_client
    @xmlrpc_client ||= begin
                         uri = data['api_url'].to_s.sub('https://', "https://#{data['user_id'].to_s}:#{data['password'].to_s}@")
                         client = XMLRPC::Client.new2(uri)
                         # call for auth check
                         client.call('backlog.getProjects')
                         client
                       rescue XMLRPC::FaultException
                         raise_config_error "Invalid login details"
                       rescue SocketError, RuntimeError
                         raise_config_error "Invalid server url"
                       end
  end

  def sort_commits(commits)
    issue_commits = Hash.new{|k,v| k[v] = []}
    commits.each do |commit|
      commit.issue.each do |issue|
        issue_commits[issue] << commit
      end
    end
    return issue_commits
  end

  def post(issue, repository, commits, branch_name)
    if commits.length == 0
      return
    end

    branch_str = branch_name.empty? ? "" : "#{branch_name} at "
    message = "pushed to #{branch_str}#{repository}\n\n"

    commits.each do |commit|
      comment = "#{message}#{commit.comment}"
      begin
        if commit.status
          xmlrpc_client.call('backlog.switchStatus', {'key' => issue, 'statusId' => commit.status, 'comment' => comment})
        else
          xmlrpc_client.call('backlog.addComment', {'key' => issue, 'content' => comment})
        end
      rescue XMLRPC::FaultException
        raise_config_error "failed post"
      rescue RuntimeError
        raise_config_error "failed post"
      end
    end
  end

  class Commit
    attr_reader :status, :issue, :url, :id

    def initialize(commit_hash)
      @id = commit_hash['id'].to_s
      @url = commit_hash['url'].to_s
      @message = commit_hash['message'].to_s
      @status = nil
      @issue = []

      re_issue_key = /(?:\[\[)?(([A-Z0-9]+(?:_[A-Z0-9]+)*)-([1-9][0-9]*))(?:\]\])?/
      temp = @message
      while temp =~ re_issue_key
        issue << $1
        temp.sub!($1, '')
      end

      re_status = /(?:^|\s+?)(#fixes|#fixed|#fix|#closes|#closed|#close)(?:\s+?|$)/
      while @message =~ re_status
        switch = $1
        @message.sub!(switch, '')
        @status = (switch =~ /fix/) ? 3 : 4
      end
    end

    def comment()
      output = "#{@url}\n"
      output += @message.strip
      return output
    end
  end
end
