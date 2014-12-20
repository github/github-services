class Service::XmppIm < Service::HttpPost
    
  self.title = 'XMPP IM'
  self.hook_name = 'xmpp_im'
    
  string :JID, :receivers
  password :password
  boolean :active, :notify_fork, :notify_wiki, :notify_comments,
    :notify_issue, :notify_watch, :notify_pull

  white_list :filter_branch, :JID, :receivers

  default_events :push, :commit_comment, :issue_comment,
    :issues, :pull_request, :pull_request_review_comment,
    :gollum
    
  def receive_event
    check_config data
      
    commit_branch = (payload['ref'] || '').split('/').last || ''
    filter_branch = data['filter_branch'].to_s

    # If filtering by branch then don't make a post
    if (filter_branch.length > 0) && (commit_branch.index(filter_branch) == nil)
      return false
    end
    
    return false if event.to_s =~ /fork/ && config_boolean_false?('notify_fork')
    return false if event.to_s =~ /watch/ && config_boolean_false?('notify_watch')
    return false if event.to_s =~ /_comment/ && config_boolean_false?('notify_comments')
    return false if event.to_s =~ /gollum/ && config_boolean_false?('notify_wiki')
    return false if event.to_s =~ /issue/ && config_boolean_false?('notify_issue')
    return false if event.to_s =~ /pull_/ && config_boolean_false?('notify_pull')
    build_message(event, payload)
    return true
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
      when :gollum
        messages = []
        messages << "#{gollum_summary_message} #{url}"
        pages.first(3).map {
            | page | messages << self.format_wiki_page_message(page)
        }
        send_messages messages
    end
    
  end
    
  def send_messages(messages)
    messages = Array(messages)
    setup_connection()
    @receivers.each do |receiver|
      messages.each do |message|
        @client.send ::Jabber::Message::new(receiver, message)
      end
    end
    ensure
      @client.close if @client
  end
    
  def setup_connection
      if (@client.nil?)
        begin
          @client = ::Jabber::Client.new(::Jabber::JID::new(@data['JID']))
          @client.connect
          @client.auth(@data['password'])
          ::Jabber::debug = true
        rescue ::Jabber::ErrorResponse
          raise_config_error 'Error response'
        rescue ::Jabber::ClientAuthenticationFailure
          raise_config_error 'Authentication error'
        rescue ::Jabber::JabberError
          raise_config_error "XMPP Error: #{$!.to_s}"
        rescue StandardError => e
          raise_config_error "Unknown error: #{$!.to_s}"
        end
      end
      @client
  end
    
  def set_connection(client)
      @client = client
  end
          
  def check_config(data)
    raise_config_error 'JID is required' if data['JID'].to_s.empty?
    raise_config_error 'Password is required' if data['password'].to_s.empty?
    raise_config_error 'Receivers list is required' if data['receivers'].to_s.empty?
    @receivers = Array.new
    data['receivers'].split().each do |jid|
      begin
        @receivers.push(::Jabber::JID.new(jid))
      rescue Exception => e
        raise_config_error 'Illegal receiver JID'
      end
    end
    @data = data
  end

  def url
    shorten_url(summary_url) if not @data['is_test']
    summary_url
  end

  def gollum_summary_message
      num = pages.length
      "[#{payload['repository']['name']}] @#{sender.login} modified #{num} page#{num != 1 ? 's' : ''}" 
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def format_wiki_page_message(page)
    url = page['html_url']
    url = shorten_url(url) if not @data['is_test']
    "User #{page['action']} page \"#{page['title']}\" #{url}"
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

  url 'http://xmpp.org/rfcs/rfc6121.html'
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
