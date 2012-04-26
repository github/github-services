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
      content = tpl.render 'event' => payload
      puts "-----"
      puts content
      puts "-----"
      
      # TODO: send message content to committer + configured recipients
      # can email.rb be used?
      recipients = data['recipients']
    }

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