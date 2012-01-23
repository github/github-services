require File.expand_path('../helper', __FILE__)

class BugzillaTest < Service::TestCase
  def setup
    @server = FakeXMLRPC.new()
  end

  def test_push
    modified_payload = modify_payload(payload)
    svc = service({'server_url' => 'nowhere', 'username' => 'someone', 'password' => '12345', 'central_repository' => false}, modified_payload)
    svc.xmlrpc_client = @server
    svc.receive_push

    assert !@server.bug_posts.include?(4) # fake server says this was already pushed somewhere else
    assert @server.closed_bugs.length == 0 # shouldn't close any bugs because this isn't the central repository
    assert @server.bug_posts[1].include? ' master at ' # check that branch name is included
    assert @server.bug_posts[1].include? 'Commits' #check for plural
    assert @server.bug_posts[1].include? '5057e76a11abd02e83b7d3d3171c4b68d9c88480'
    assert @server.bug_posts[1].include? 'a47fd41f3aa4610ea527dcc1669dfdb9c15c5425'
    assert @server.bug_posts[2].include? '5057e76a11abd02e83b7d3d3171c4b68d9c88480'
    assert @server.bug_posts[3].include? '5057e76a11abd02e83b7d3d3171c4b68d9c88480'
  end

  # Verify pushes will be processed on all commits if no integration branch is specified.
  def test_integration_branch_is_optional
    modified_payload = modify_payload(payload)
    svc = service({'server_url' => 'nowhere', 'username' => 'someone', 'password' => '12345', 'central_repository' => true}, modified_payload)
    svc.xmlrpc_client = @server
    svc.receive_push

    assert @server.closed_bugs.include?(1)
    assert @server.bug_posts.include?(4)
  end

  # Verify commits are only processed if they are in our integration branch.
  def test_integration_branch
    # No commits should be processed for this push because we're only listening for
    # commits landing on the "master" branch.
    modified_payload = modify_payload(payload).merge({'ref' => 'refs/heads/development'})
    svc = service({'server_url' => 'nowhere', 'username' => 'someone', 'password' => '12345', 'integration_branch' => 'master', 'central_repository' => true}, modified_payload)
    svc.xmlrpc_client = @server
    svc.receive_push

    assert @server.closed_bugs.length == 0
    assert @server.bug_posts.length == 0

    # This time, we should close a bug and post 4 comments because these commits were
    # pushed to our integration branch.
    modified_payload = modify_payload(payload).merge({'ref' => 'refs/heads/master'})
    svc = service({'server_url' => 'nowhere', 'username' => 'someone', 'password' => '12345', 'integration_branch' => 'master', 'central_repository' => true}, modified_payload)
    svc.xmlrpc_client = @server
    svc.receive_push

    assert @server.closed_bugs.include?(1)
    assert @server.bug_posts.include?(4)
  end

  def test_central_push
    #test pushing to a central repository
    modified_payload = modify_payload(payload)
    svc = service({'server_url' => 'nowhere', 'username' => 'someone', 'password' => '12345', 'central_repository' => true}, modified_payload)
    svc.xmlrpc_client = @server
    svc.receive_push

    assert @server.closed_bugs.include?(1)
    assert @server.bug_posts.include?(4) # fake server says this was already pushed somewhere else
  end

  def modify_payload(payload)
    #modify payload to include some bug numbers and close a bug
    modified_payload = payload.clone()
    modified_payload['commits'][0]['message'] << "\nBug:4"
    modified_payload['commits'][1]['message'] << "\nTracker items 1, 2 and 3"
    modified_payload['commits'][2]['message'] << "\nCloses tracker item 1"
    return modified_payload
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
      when 'Bug.update'
        closed_bugs.push *arguments['ids']
      end
    end

    def bug_posts
      @bug_posts ||= {}
    end

    def closed_bugs
      @closed_bugs ||= []
    end
  end
end

