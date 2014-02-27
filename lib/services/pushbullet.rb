class Service::Pushbullet < Service

  string :api_key, :device_iden

  default_events :push, :issues, :pull_request

  url "https://www.pushbullet.com/"
  logo_url "https://lh3.ggpht.com/hlxRPX7B5J28cgGAZcovaT-7wLimLi0wPi7dSI6udH5NGI58WTBezGgpJyIepZhBRp4=w500"

  maintained_by :github => 'tuhoojabotti',
    :twitter => 'tuhoojabotti',
    :web => 'http://tuhoojabotti.com/#contact'

  supported_by :web => 'https://www.pushbullet.com/help',
    :email => 'hey@pushbullet.com'

  def receive_push
    check_config

    return unless commits.any?

    if commits.length == 1
      title = "#{pusher_name} pushed to #{name_with_owner}"
      message = commit_messages.first
    else
      title = "#{pusher_name} pushed #{commits.length} commits..."
      message = "To #{name_with_owner}:\nL#{commit_messages.join("\n")}"
    end

    push_message title, message
  end

  def receive_issue
    check_config

    p = self.class.objectify payload
    repo = p.repository
    body = truncate_too_long issue.body, 300

    title = "%s %s issue #%d" % [p.sender.login, p.action, issue.number]
    msg = "In %s/%s: \"%s\"\n%s" % [repo.owner.login, repo.name, issue.title,
      body]

    push_message title, msg

  end

  def receive_pull_request
    check_config

    p = self.class.objectify payload
    repo = p.repository
    body = truncate_too_long pull.body, 200

    base_ref = pull.base.label.split(':').last
    head_ref = pull.head.label.split(':').last
    head_ref = pull.head.label if head_ref == base_ref

    title = "%s %s pull request #%d" % [p.sender.login, p.action, pull.number]
    msg = "In %s/%s: \"%s\" (%s...%s)\n%s" % [repo.owner.login, repo.name,
      pull.title, base_ref, head_ref, body]

    push_message title, msg
  end

  private

  def check_config
    @api_key = data["api_key"].to_s
    @iden = data["device_iden"].to_s
    raise_config_error "Invalid or missing api key." unless @api_key.match(/\A[a-zA-Z0-9]{32}\z/)
    raise_config_error "Invalid or missing device iden." unless @iden.match(/\A[a-zA-Z0-9]{16}\z/)
  end

  def push_message(title, message)
    # set api key
    http.basic_auth(@api_key, "")

    # call api
    http_post "https://api.pushbullet.com:443/api/pushes",
      :device_iden => @iden,
      :type => "note",
      :title => title,
      :body => message
  end

  def truncate_too_long(str, len)
    str.length > len ? str[0..len].gsub(/\s\w+\s*$/, '...') : str
  end
end