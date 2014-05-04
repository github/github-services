class Service::XmppMuc < Service
    
  self.title = 'XMPP MUC Poster'
  self.hook_name = 'xmpp_muc'
    
  string :JID, :room, :server, :nickname
  password :password, :room_password
  boolean :active, :notify_fork, :notify_wiki, :notify_comments,
    :notify_watch, :notify_issue, :notify_deployment, :notify_team

  white_list :room, :filter_branch, :JID, :room, :server, :nickname

  default_events :commit_comment, :create, :delete, :download, 
    :follow, :fork, :fork_apply, 
    :gist, :gollum, :issue_comment,
    :issues, :member, :public, :pull_request, :push, :team_add, 
    :watch, :pull_request_review_comment,
    :status, :release, :deployment, :deployment_status

  def receive_event
    check_config data
      
    commit_branch = (payload['ref'] || '').split('/').last
    filter_branch = data['filter_branch'].to_s

    # If filtering by branch then don't make a post
    if (filter_branch.length > 0) && (filter_branch.index(commit_branch) == nil)
      return false
    end
    
    return false if event.to_s =~ /fork/ && !data['notify_fork']
    return false if event.to_s =~ /watch/ && !data['notify_watch']
    return false if event.to_s =~ /_comment/ && !data['notify_comments']
    return false if event.to_s =~ /gollum/ && !data['notify_wiki']
    return false if event.to_s =~ /issue/ && !data['notify_issue']
    return false if event.to_s =~ /pull_/ && !data['notify_pull']
    return false if event.to_s =~ /deployment/ && !data['notify_deployment']
    return false if event.to_s =~ /team/ && !data['notify_team']
    return false if event.to_s =~ /release/ && !data['notify_release']

    build_message(event, payload)
  end
    
  def build_message(event, payload)
    case event
      when :push
        messages = []
        messages << "#{push_summary_message}: #{url}"
        messages += distinct_commits.first(3).map {
            |commit| self.format_commit_message(commit)
        }
        send_messages messages
      when :commit_comment
        send_messages "#{commit_comment_summary_message} #{url}"
      when :issue_comment
        send_messages "#{issue_comment_summary_message} #{url}"
      when :issues
        send_messages "#{issue_summary_message} #{url}"
      when :pull_request
        send_messages "#{pull_request_summary_message} #{url}" if action =~ /(open)|(close)/
      when :pull_request_review_comment
        send_messages "#{pull_request_review_comment_summary_message} #{url}"
      when :create
      when :delete
      when :download
      when :follow
      when :fork
      when :fork_apply
      when :gist
      when :gollum
      when :member
      when :public
      when :push
      when :team_add
      when :watch
      when :status
      when :release
      when :deployment
      when :deployment_status
    end
    
  end
    
  def send_messages(messages)
    messages = Array(messages)
    setup_muc_connection()
    messages.each do |message|
        @muc.send ::Jabber::Message::new(::Jabber::JID.new(@data['muc_room']), message)
    end
    @muc.exit
    ensure
      @client.close if @client
  end
    
  def setup_muc_connection
      if (@muc.nil?)
        begin
          @client = ::Jabber::Client.new(::Jabber::JID::new(@data['JID']))
          @client.connect
          @client.auth(@data['password'])
          ::Jabber::debug = true
          @muc = ::Jabber::MUC::MUCClient.new(@client)
          @muc.join(::Jabber::JID.new(@data['muc_room']), @data['password'])
        rescue ::Jabber::ErrorResponse
          raise_config_error 'Error response'
        rescue ::Jabber::ClientAuthenticationFailure
          raise_config_error 'Authentication error'
        rescue ::Jabber::JabberError
          raise_config_error 'XMPP Error'
        else
          raise_config_error 'Unknown error'
        end
      end
      @muc
  end
    
  def set_muc_connection(muc)
      @muc = muc
  end
          
  def check_config(data)
    raise_config_error 'JID is required' if data['JID'].to_s.empty?
    raise_config_error 'Password is required' if data['password'].to_s.empty?
    raise_config_error 'Room is required' if data['room'].to_s.empty?
    raise_config_error 'Server is required' if data['server'].to_s.empty?
    data['nickname'] = 'github' if data['nickname'].to_s.empty?

    data['muc_room'] = "#{data['room']}@#{data['server']}/#{data['nickname']}"
    @data = data
  end

  def url
    shorten_url(summary_url) if not @data['is_test']
    summary_url
  end

  def push_summary_message
    message = []
    message << "[#{repo_name}] @#{pusher_name}"

    if created?
      if tag?
        message << "tagged #{tag_name} at"
        message << (base_ref ? base_ref_name : after_sha)
      else
        message << "created #{branch_name}"

        if base_ref
          message << "from #{base_ref_name}"
        elsif distinct_commits.empty?
          message << "at #{after_sha}"
        end

        num = distinct_commits.size
        message << "(+#{num} new commit#{num != 1 ? 's' : ''})"
      end

    elsif deleted?
      message << "deleted #{branch_name} at #{before_sha}"

    elsif forced?
      message << "force-pushed #{branch_name} from #{before_sha} to #{after_sha}"

    elsif commits.any? and distinct_commits.empty?
      if base_ref
        message << "merged #{base_ref_name} into #{branch_name}"
      else
        message << "fast-forwarded #{branch_name} from #{before_sha} to #{after_sha}"
      end

    else
      num = distinct_commits.size
      message << "pushed #{num} new commit#{num != 1 ? 's' : ''} to #{branch_name}"
    end

    message.join(' ')
  end

  def format_commit_message(commit)
    short  = commit['message'].split("\n", 2).first.to_s
    short += '...' if short != commit['message']

    author = commit['author']['name']
    sha1   = commit['id']
    files  = Array(commit['modified'])
    #dirs   = files.map { |file| File.dirname(file) }.uniq

    "#{repo_name}/#{branch_name} #{sha1[0..6]} " +
    "#{commit['author']['name']}: #{short}"
  end

  def issue_summary_message
    "[#{repo.name}] @#{sender.login} #{action} issue \##{issue.number}: #{issue.title}"
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def issue_comment_summary_message
    short  = comment.body.split("\r\n", 2).first.to_s
    short += '...' if short != comment.body
    "[#{repo.name}] @#{sender.login} commented on issue \##{issue.number}: #{short}"
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def commit_comment_summary_message
    short  = comment.body.split("\r\n", 2).first.to_s
    short += '...' if short != comment.body
    sha1   = comment.commit_id
    "[#{repo.name}] @#{sender.login} commented on commit #{sha1[0..6]}: #{short}"
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def pull_request_summary_message
    base_ref = pull.base.label.split(':').last
    head_ref = pull.head.label.split(':').last
    head_label = head_ref != base_ref ? head_ref : pull.head.label

    "[#{repo.name}] @#{sender.login} #{action} pull request " +
    "\##{pull.number}: #{pull.title} (#{base_ref}...#{head_ref})"
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def pull_request_review_comment_summary_message
    short  = comment.body.split("\r\n", 2).first.to_s
    short += '...' if short != comment.body
    sha1   = comment.commit_id
    "[#{repo.name}] @#{sender.login} commented on pull request " +
    "\##{pull_request_number} #{sha1[0..6]}: #{short}"
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  url 'http://xmpp.org/extensions/xep-0045.html'
  logo_url 'http://xmpp.org/images/xmpp-small.png'

  # lloydwatkin on GitHub is <del>pinged</del> contacted for any bugs with the Hook code.
  maintained_by :github => 'lloydwatkin'

  # Support channels for user-level Hook problems (service failure,
  # misconfigured
  supported_by :web => 'http://github.com/lloydwatkin/github-services/issues',
               :email => 'lloyd@evilprofessor.co.uk',
               :twitter => 'lloydwatkin',
               :github => 'lloydwatkin'
end