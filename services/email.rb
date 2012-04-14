class Net::SMTP
  def mailfrom(from_addr)
    from_addr = from_addr[/<([^>]+)>/, 1] if from_addr.include?('<')

    if $SAFE > 0
      raise SecurityError, 'tainted from_addr' if from_addr.tainted?
    end
    getok("MAIL FROM:<#{from_addr}>")
  end
end

class Service::Email < Service
  string :address, :secret
  boolean :send_from_author, :show_diff
  boolean :send_pull_requests, :send_issues

  def receive_push
    send_message
  end

  def receive_pull_request
    send_message if data['send_pull_requests']
  end

  def receive_issue
    send_message if data['send_issues']
   end

  def send_message
    configure_mail_defaults unless mail_configured?

    addresses.each do |address|
      send_message_to address
    end
  end

  def send_message_to(address)
    send_mail mail_message(address)
  end

  def send_mail(mail)
    mail.deliver!
  end

  def configure_mail_defaults
    my = self

    Mail.defaults do
      delivery_method :smtp,
        :address              => my.smtp_address,
        :port                 => my.smtp_port,
        :domain               => my.smtp_domain,
        :user_name            => my.smtp_user_name,
        :password             => my.smtp_password,
        :authentication       => my.smtp_authentication,
        :enable_starttls_auto => my.smtp_enable_starttls_auto?,
        :openssl_verify_mode  => my.smtp_openssl_verify_mode
    end

    mail_configured!
  end

  def mail_configured?
    defined?(@@mail_configured) && @@mail_configured
  end

  def mail_configured!
    @@mail_configured = true
  end

  def addresses
    data['address'].split(' ').slice(0, 2)
  end

  def mail_message(address)
    my = self

    if @event == :push
      from = my.from_address
      subject = my.mail_subject
      body = my.text_body
    else
      from = my.noreply_address
      subject = my.summary_message
      if @event == :issues
        body << <<-EOM
See #{my.html_url}

#{my.title}

#{my.body}
EOM
      elsif @event == :pull_request
        body << <<-EOM
See #{my.html_url}

#{my.sender.login} #{my.action} #{my.title}

#{my.body}
EOM
      else
        body = my.summary_url
      end
    end

    Mail.new do
      to       address
      from     from
      reply_to from
      subject  subject
      headers  my.secret_header

      text_part do
        content_type 'text/plain; charset=UTF-8'
        body         body
      end
    end
  end


  def text_body
    body = commits.inject(repository_text) do |text, commit|
      text << commit_text(commit)
    end

    body << compare_text unless single_commit?

    body
  end

  def repository_text
    align(<<-EOH)
      Branch: #{branch_ref}
      Home:   #{repo_url}
    EOH
  end

  def commit_text(commit)
    gitsha   = commit['id']
    added    = commit['added'].map    { |f| ['A', f] }
    removed  = commit['removed'].map  { |f| ['R', f] }
    modified = commit['modified'].map { |f| ['M', f] }

    changed_paths = (added + removed + modified).sort_by { |(char, file)| file }
    changed_paths = changed_paths.collect { |entry| entry * ' ' }.join("\n    ")

    timestamp = Date.parse(commit['timestamp'])

    commit_author = "#{commit['author']['name']} <#{commit['author']['email']}>"

    text = align(<<-EOH)
      Commit: #{gitsha}
          #{commit['url']}
      Author: #{commit_author}
      Date:   #{timestamp} (#{timestamp.strftime('%a, %d %b %Y')})

    EOH

    if changed_paths.size > 0
      text << align(<<-EOH)
        Changed paths:
          #{changed_paths}

      EOH
    end

    text << align(<<-EOH)
      Log Message:
      -----------
      #{commit['message']}


    EOH

    if data['show_diff']
      begin
        patch_resp = http_get commit['url'] + ".diff" do |req| # Github currently doesn't support Accept headers
          req[:timeout] = '4' # seconds
        end
        case patch_resp.status
        when 301, 302, 303, 307, 308
          patch_resp = http_get patch_resp.headers['location'] do |req|
            req[:timeout] = '4' # seconds
          end
        end
        if patch_resp.success?
          text << patch_resp.body
        else
          raise "Status: #{patch_resp.status}"
        end
      rescue => msg
        text << "There was an error trying to read the diff from github.com (#{msg})"
      end
      text << <<-EOH


      EOH
      text << "================================================================\n"
    end

    text
  end

  def compare_text
    "Compare: #{payload['compare']}"
  end

  def single_commit?
    first_commit == last_commit
  end

  def branch_ref
    payload['ref']
  end

  def repo_url
    payload['repository']['url']
  end

  def mail_subject
    if first_commit
      "[#{name_with_owner}] #{first_commit_sha.slice(0, 6)}: #{first_commit_title}"
    else
      "[#{name_with_owner}]"
    end
  end

  def secret_header
    secret ? {'Approved' => secret} : {}
  end

  def from_address
    send_from_author? ? author_address : noreply_address
  end

  def send_from_author?
    data['send_from_author']
  end

  def author_address
    "#{author_name} <#{author_email}>"
  end

  def author
    commit = last_commit || {}
    commit['author'] || commit['committer'] || payload['pusher']
  end

  def author_name
    author['name']
  end

  def author_email
    author['email']
  end

  def last_commit
    payload['commits'].last # assume that the last committer is also the pusher
  end

  def secret
    data['secret'] if data['secret'].to_s.size > 0
  end

  def name_with_owner
    File.join(owner_name, repository_name)
  end

  def owner_name
    payload['repository']['owner']['name']
  end

  def repository_name
    payload['repository']['name']
  end

  def first_commit_sha
    first_commit['id']
  end

  def first_commit_title(limit = 50)
    title_line = first_commit['message'][/\A[^\n]+/] || ''

    title_line.length > limit ? shorten(title_line, limit) : title_line
  end

  def shorten(text, limit)
    text.slice(0, limit) << '...'
  end

  def first_commit
    payload['commits'].first
  end

  def align(text, indent = '  ')
    margin = text[/\A\s+/].size

    text.gsub(/^\s{#{margin}}/, indent)
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
    @smtp_enable_starttls_auto ||= (email_config['enable_starttls_auto'] && true)
  end

  def smtp_openssl_verify_mode
    @smtp_openssl_verify_mode ||= email_config['openssl_verify_mode']
  end

  def smtp_logging?
    @smtp_logging ||= email_config['enable_logging']
  end

  def noreply_address
    @noreply_address ||= email_config['noreply_address'] || "GitHub <noreply@github.com>"
  end
end
