class Service::Email < Service
  string :address, :secret
  boolean :send_from_author

  def receive_push
    name_with_owner = File.join(payload['repository']['owner']['name'], payload['repository']['name'])

    # Should be: first_commit = payload['commits'].first
    first_commit = payload['commits'].first
    return if first_commit.nil?

    first_commit_sha = first_commit['id']

    # Shorten the elements of the subject
    first_commit_sha = first_commit_sha[0..5]

    first_commit_title = first_commit['message'][/^([^\n]+)/, 1] || ''
    if first_commit_title.length > 50
      first_commit_title = first_commit_title.slice(0,50) << '...'
    end

    body = <<-EOH
  Branch: #{payload['ref']}
  Home:   #{payload['repository']['url']}

  EOH

    payload['commits'].each do |commit|
      gitsha   = commit['id']
      added    = commit['added'].map    { |f| ['A', f] }
      removed  = commit['removed'].map  { |f| ['R', f] }
      modified = commit['modified'].map { |f| ['M', f] }

      changed_paths = (added + removed + modified).sort_by { |(char, file)| file }
      changed_paths = changed_paths.collect { |entry| entry * ' ' }.join("\n  ")

      timestamp = Date.parse(commit['timestamp'])

      body << <<-EOH
  Commit: #{gitsha}
      #{commit['url']}
  Author: #{commit['author']['name']} <#{commit['author']['email']}>
  Date:   #{timestamp} (#{timestamp.strftime('%a, %d %b %Y')})

  EOH

      if changed_paths.size > 0
        body << <<-EOH
  Changed paths:
    #{changed_paths}

  EOH
      end

      body << <<-EOH
  Log Message:
  -----------
  #{commit['message']}


  EOH
    end

    body << "Compare: #{payload['compare']}" if payload['commits'].size > 1
    commit = payload['commits'].last # assume that the last committer is also the pusher

    begin
      data['address'].split(' ').slice(0, 2).each do |address|
        message = TMail::Mail.new
        message.set_content_type('text', 'plain', {:charset => 'UTF-8'})
        message.from = "#{commit['author']['name']} <#{commit['author']['email']}>" if data['send_from_author']
        message.reply_to = "#{commit['author']['name']} <#{commit['author']['email']}>" if data['send_from_author']
        message.to      = address
        message.subject = "[#{name_with_owner}] #{first_commit_sha}: #{first_commit_title}"
        message.body    = body
        message.date    = Time.now

        message['Approved'] = data['secret'] if data['secret'].to_s.size > 0

        if data['send_from_author']
          send_message message, "#{commit['author']['name']} <#{commit['author']['email']}>", address
        else
          send_message message, "GitHub <noreply@github.com>", address
        end
      end
    end
  end

  def smtp_address
    @smtp_address ||= email_config['address']
  end

  def smtp_port
    @smtp_port ||= (email_config['port'] || 25).to_i
  end

  def smtp_domain
    @smtp_domain ||= email_config['domain'] || 'localhost.localdomain'
  end

  def smtp_authentication
    @smtp_authentication ||= email_config['authentication']
  end

  def smtp_user_name
    @smtp_user_name ||= email_config['user_name']
  end

  def smtp_password
    @smtp_password ||= email_config['password']
  end

  def smtp_enable_starttls_auto?
    @smtp_enable_starttls_auto ||= email_config['enable_starttls_auto']
  end

  def smtp_openssl_verify_mode
    @smtp_openssl_verify_mode ||= email_config['openssl_verify_mode']
  end

  def smtp_settings
    settings = [smtp_address, smtp_port, smtp_domain]

    if smtp_authentication
      settings.push smtp_user_name, smtp_password, smtp_authentication
    end

    settings
  end

  def send_message(message, from, to)
    smtp = Net::SMTP.new(smtp_address, smtp_port)

    configure_tls(smtp) if smtp_enable_starttls_auto?

    smtp.start(*smtp_settings) do |smtp|
      smtp.send_message message.to_s, from, to
    end
  rescue Net::SMTPSyntaxError, Net::SMTPFatalError
    raise_config_error "Invalid email address"
  end

  def configure_tls(smtp)
    if smtp_openssl_verify_mode
      if openssl_verify_mode.kind_of?(String)
        openssl_verify_mode = "OpenSSL::SSL::VERIFY_#{openssl_verify_mode.upcase}".constantize
      end

      context = Net::SMTP.default_ssl_context
      context.verify_mode = openssl_verify_mode
      smtp.enable_starttls_auto(context)
    else
      smtp.enable_starttls_auto
    end
  end
end
