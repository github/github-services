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
    # TODO: check config params: message_format, template
    
    # remove commits with valid message
    fmt = data['message_format']
    payload['commits'].delete_if { |c| c['message'] =~ /#{fmt}/ }
    
    # render email message with template
    repository = payload['repository']['url']
    tpl = get_template(repository)
    content = tpl.render 'event' => payload
    puts "-----"
    puts content
    puts "-----"
    
    recipients = data['recipients']
    # TODO: - get pusher email address (check event data format)

    # TODO: - send email
  end
  
  def templates
    @templates ||= Hash.new
  end
  
  def get_template(repository)
    # assume there can be only one template instance per repository
    if !templates[repository]
      templates[repository] = Liquid::Template.parse(data['template'])
    end
    templates[repository]
  end
  
end