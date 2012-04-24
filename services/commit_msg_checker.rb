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
    print "foo\n"
    
    # TODO: check config params: message_format, template
    
    # remove commits with valid message
    fmt = data['message_format']
    payload['commits'].delete_if { |c| c['message'] =~ /#{fmt}/
    }
    
    # render email message with template
    content = Liquid::Template.parse(data['template']).render 'event' => payload
    puts "-----"
    puts content
    puts "-----"
    
    # TODO: send email
    
    # debugging, remove
    print payload['commits'].length
    payload['commits'].each { |c|
      puts "key: ",c['message']
    }
    print "data: ",data['message_format'],"\n"
  end
end