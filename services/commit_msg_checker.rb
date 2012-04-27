#
# Git commit message format checker.
#
# This class is a Github service hook that checks the commit messages
# for each push event adhere to a specified format. 
# The message format and email templates are user configurable. 
#
# Author:: Marko Asplund
#

require "liquid"


class Service::CommitMsgChecker < Service

  def receive_push
    fmt = data['message_format']
    repository = payload['repository']['url']

    # validate configuration parameters
    begin
      re = /#{fmt}/
      tpl = get_template(repository)
    rescue RegexpError
      raise_config_error "Invalid commit message format specification"
    rescue Liquid::SyntaxError
      raise_config_error "Invalid message template"
    end
    cc = data['recipients'].split
    data['template']
    subject = data['subject']

    
    # remove commits with valid message
    payload['commits'].delete_if { |c| c['message'] =~ re }

    commits = payload['commits']
    committers = Set.new
    commits.each { |c|
      committers.add(c['committer']['email'])
    }

    
    committers.each { |committer|
      ccommits = []
      commits.each { |c|
        if c['committer']['email'] == committer
          ccommits.push(c)
        end
      }
      payload['commits'] = ccommits

      # render email message with template
      content = tpl.render 'event' => payload
      
      # send notification to committer + configured recipients
      deliver_message([committer], cc, subject, content)
    }

  end

  def deliver_message(to, cc, subject, content)
    configure_delivery unless mail_configured?
    
    mail_message(to, cc, subject, content).deliver
  end

  def configure_delivery(config)
    configure_mail_defaults
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

    @@mail_configured = true
  end

  def mail_configured?
    defined?(@@mail_configured) && @@mail_configured
  end

  def mail_message(to, cc, subject, body)
    my = self
    
    Mail.new do
      to       to
      cc       cc
      from     my.mail_from
      reply_to my.mail_from
      subject  subject
      headers  my.secret_header

      text_part do
        content_type 'text/plain; charset=UTF-8'
        body         body
      end
    end
  end
  
  def templates
    @templates ||= Hash.new
  end
  
  def get_template(repository)
    # assume there can be only one template instance per repository
    if !templates[repository]
      tpl = data['template']
      templates[repository] = Liquid::Template.parse(tpl)
    end
    templates[repository]
  end

  def default_email_template
    tpl = <<HERE
{% for c in event.commits %}
  commit: {{ c.id }}
{% endfor %}
HERE
  end

end