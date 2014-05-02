class Service::XmppMuc < Service
    
  self.title = 'XMPP MUC Poster'
  self.hook_name = 'xmpp_muc'
    
  string :JID, :room, :server, :nickname
  password :password
  boolean :notify, :notify_fork, :notify_watch, :notify_comments, :notify_wiki
  white_list :room, :filter_branch

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
      return
    end
  end
    
  def check_config(data)
    
    raise_config_error 'JID is required' if data['JID'].to_s.empty?
    raise_config_error 'Password is required' if data['password'].to_s.empty?
    raise_config_error 'Room is required' if data['room'].to_s.empty?
    raise_config_error 'Server is required' if data['server'].to_s.empty?
    data['nickname'] = 'github' if data['nickname'].to_s.empty?

    data['muc_room'] = "#{data['room']}@#{data['server']}/#{data['nickname']}"

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