require File.expand_path('../helper', __FILE__)

class BugzillaTest < Service::TestCase
  def setup
    @server = FakeXMLRPC.new()
  end

  def test_push
    modified_payload = payload.clone()
    #modify payload to include some bug numbers
    modified_payload['commits'][0]['message'] << "\nBug:4"
    modified_payload['commits'][1]['message'] << "\nTracker items 1, 2 and 3"
    modified_payload['commits'][2]['message'] << "\nTracker item 1"
    svc = service({'server_url' => 'nowhere', 'username' => 'someone', 'password' => '12345'}, modified_payload)
    svc.xmlrpc_client = @server
    svc.receive_push

    assert !@server.bug_posts.include?(4) # fake server says this was already pushed somewhere else
    assert @server.bug_posts[1].include? 'Commits' #check for plural
    assert @server.bug_posts[1].include? '5057e76a11abd02e83b7d3d3171c4b68d9c88480'
    assert @server.bug_posts[1].include? 'a47fd41f3aa4610ea527dcc1669dfdb9c15c5425'
    assert @server.bug_posts[2].include? '5057e76a11abd02e83b7d3d3171c4b68d9c88480'
    assert @server.bug_posts[3].include? '5057e76a11abd02e83b7d3d3171c4b68d9c88480'
  end

  def service(*args)
    super Service::Bugzilla, *args
  end

  class FakeXMLRPC
    def call(procedure, arguments)
      case procedure
      when 'User.login'
        # Do nothing
      when 'Bug.add_comment'
        bug_posts[arguments['id']] = arguments['comment']
      when 'Bug.comments'
        # Pretend this commit has already been pushed to another user's repository
        return {'bugs'=>{"#{arguments['ids'][0]}"=>{'comments'=>[{'text'=>'06f63b43050935962f84fe54473a7c5de7977325'}]}}}
      end
    end

    def bug_posts
      @bug_posts ||= {}
    end
  end
end

