class Service::PubAlert < Service
  #
  # Post to URL when Repo toggles from Private to Public
  #

  string :remote_url,
    # (Required) The remote URL to POST data towards (eg: "https://com.example/webhook/github"
    :auth_token,
    # (Required) Authentication Token to be used by the POST URL
    :repo_name,
    # (Required) Repo name which triggered this Event.
    :notify_email
    # (Optional) Email Address(1) to intimate that Public Event is generated

  default_events :public

  def receive_public
    # make sure we have what we need
    raise_config_error "Missing 'remote_url'" if data['remote_url'].to_s == ''
    raise_config_error "Missing 'auth_token'" if data['auth_token'].to_s == ''
    raise_config_error "Missing 'repo_name'" if data['repo_name'].to_s == ''

    # Set our headers
    http.headers['X-GitHub-Event'] = event.to_s #this should be 'public' anyway

    begin
      res = http_post "#{data['remote_url']}",
              {:auth_token => data['auth_token'],
               :repo_name => data['repo_name']}
      if res.status < 200 || res.status > 299
        raise_config_error
      end
    rescue URI::Error => e
      raise_config_error "Not able to send a POST request to #{data['remote_url']}. Reason being:%s" % e.message
    end

    notify_email = data['notify_email'].split(/[, ]/).compact.reject {|s| s.nil? or s.empty? }[0]

    begin
      notify_event notify_email, data['repo_name'] if notify_email
    rescue Net::SMTPError => e
      raise_config_error "Not able to shoot email to #{notify_email}. Reason being:%s" % e.message
    end
  end

  def notify_event(address, repo_name)
    my = self
    Mail.defaults do
      delivery_method :smtp, { :address   => my.email_config['address'],
                           :port      => my.email_config['port'],
                           :domain    => my.email_config['domain'],
                           :user_name => my.email_config['user_name'],
                           :password  => my.email_config['password'],
                           :authentication => my.email_config['authentication'],
                           :enable_starttls_auto => my.email_config['enable_starttls_auto']}
    end
    mail_message = Mail.deliver do
      to       address
      from     "GitHub <noreply@github.com>"
      reply_to "GitHub <noreply@github.com>"
      subject  "#{repo_name} is open-sourced."
      text_part do
        content_type 'text/plain; charset=UTF-8'
        body         "#{repo_name} is open-sourced."
      end
    end
    mail_message
  end
end
