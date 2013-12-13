require File.expand_path('../helper', __FILE__)

class ChatWorkTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    post_to_service(:push)
  end

  def test_commit_comment
    post_to_service(:commit_comment)
  end

  def test_issues
    post_to_service(:issues)
  end

  def test_issue_comment
    post_to_service(:issue_comment)
  end

  def test_pull_request
    post_to_service(:pull_request)
  end

  def test_pull_request_review_comment
    post_to_service(:pull_request_review_comment)
  end

  def test_missing_token
    svc = service({ 'auth_token' => '', 'project_id' => '123' }, payload)
    assert_raise Service::ConfigurationError do
      svc.receive_event
    end
  end

  def test_missing_room_id
    svc = service({ 'auth_token' => 'xxx', 'project_id' => '' }, payload)
    assert_raise Service::ConfigurationError do
      svc.receive_event
    end
  end

  private

  def post_to_service(event_name)
    room_id = '11111'
    auth_token = 'x'

    params = { 'auth_token' => auth_token, 'room_id' => room_id }
    pre_name = event_name == :pull_request ? 'pull' : event_name
    svc = service(event_name, params, send("#{pre_name}_payload"))

    @stubs.post "/v1/rooms/#{room_id}/messages" do |env|
      assert_equal auth_token, env[:request_headers]['X-ChatWorkToken']
    end

    svc.receive_event
  end

  def service(*args)
    super Service::ChatWork, *args
  end
end
