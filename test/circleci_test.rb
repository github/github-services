require File.expand_path('../helper', __FILE__)
class CircleciTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  # currently supported events

  # commit_comment create delete download follow fork fork_apply gist gollum
  # issue_comment issues member public pull_request push team_add watch
  # pull_request_review_comment status

  def test_commit_comment
    post_to_service(:commit_comment)
  end

  def test_create
    post_to_service(:create)
  end

  def test_delete
    post_to_service(:delete)
  end

  def test_download
    post_to_service(:download)
  end

  def test_follow
    post_to_service(:follow)
  end

  def test_fork
    post_to_service(:fork)
  end

  def test_fork_apply
    post_to_service(:fork_apply)
  end

  def test_gist
    post_to_service(:gist)
  end

  def test_gollum
    post_to_service(:gollum)
  end

  def test_issue_comment
    post_to_service(:issue_comment)
  end

  def test_issues
    post_to_service(:issues)
  end

  def test_member
    post_to_service(:member)
  end

  def test_public
    post_to_service(:public)
  end

  def test_push
    post_to_service(:push)
  end


  def test_team_add
    post_to_service(:team_add)
  end

  def test_watch
    post_to_service(:watch)
  end

  def test_pull_request_review_comment
    post_to_service(:pull_request_review_comment)
  end

  def test_status
    post_to_service(:status)
  end

  def test_supported_events
    assert_equal Service::Circleci.supported_events.sort , Service::ALL_EVENTS.sort
    assert_equal Service::Circleci.default_events.sort , Service::ALL_EVENTS.sort
  end

  private

  def service(*args)
    super Service::Circleci, *args
  end

  def post_to_service(event_name)
    assert Service::ALL_EVENTS.include? event_name.to_s
    svc = service(event_name, {'token' => 'abc'}, payload)

    @stubs.post "/hooks/github" do |env|
      body = Faraday::Utils.parse_query env[:body]
      assert_match "https://circleci.com/hooks/github", env[:url].to_s
      assert_match 'application/x-www-form-urlencoded', env[:request_headers]['content-type']
      assert_equal payload, JSON.parse(body["payload"].to_s)
      assert_equal event_name.to_s, JSON.parse(body["event_type"].to_s)["event_type"]
    end

    svc.receive_event
  end
end
