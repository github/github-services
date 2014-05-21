require File.expand_path('../helper', __FILE__)

class AsanaTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push

    @stubs.post "/api/1.0/tasks/1234/stories" do |env|
      assert_match /rtomayko pushed to branch master of mojombo\/grit/, env[:body]
      assert_match /#1234/, env[:body]
      assert_match /Basic MDAwMDo=/, env[:request_headers][:authorization]
      [200, {}, '']
    end

    @stubs.post "/api/1.0/tasks/1235/stories" do |env|
      assert_match /rtomayko pushed to branch master of mojombo\/grit/, env[:body]
      assert_match /#1235/, env[:body]
      assert_match /Basic MDAwMDo=/, env[:request_headers][:authorization]
      [200, {}, '']
    end

    svc = service(
      {'auth_token' => '0000'},
      modified_payload)
    svc.receive_push
  end

  def test_restricted_comment_commit_push

    @stubs.post "/api/1.0/tasks/1234/stories" do |env|
      assert_match /rtomayko pushed to branch master of mojombo\/grit/, env[:body]
      assert_no_match /stub git call for Grit#heads test f:15 Case#1234/, env[:body]
      assert_match /add more comments about #1235 and #1234 throughout/, env[:body]
      assert_match /#1234/, env[:body]
      assert_match /Basic MDAwMDo=/, env[:request_headers][:authorization]
      [200, {}, '']
    end

    @stubs.post "/api/1.0/tasks/1235/stories" do |env|
      assert_match /rtomayko pushed to branch master of mojombo\/grit/, env[:body]
      assert_no_match /#1234 clean up heads test f:2hrs #1235/, env[:body]
      assert_match /add more comments about #1235 and #1234 throughout/, env[:body]
      assert_match /#1235/, env[:body]
      assert_match /Basic MDAwMDo=/, env[:request_headers][:authorization]
      [200, {}, '']
    end

    svc = service(
      {'auth_token' => '0000',"restrict_to_last_comment" => "1"},
      modified_payload)
    svc.receive_push
  end

  def test_restricted_branch_commit_push

    @stubs.post "/api/1.0/tasks/1234/stories" do |env|
      assert_no_match /stub git call for Grit#heads test f:15 Case#1234/, env[:body]
      [200, {}, '']
    end

    @stubs.post "/api/1.0/tasks/1235/stories" do |env|
      assert_no_match /#1234 clean up heads test f:2hrs #1235/, env[:body]
      [200, {}, '']
    end

    svc = service(
      {'auth_token' => '0000',"restrict_to_branch" => "foo,bar"},
      modified_payload)
    svc.receive_push
  end

  def test_merge_pull_request_payload
    @stubs.post "/api/1.0/tasks/42/stories" do |env|
      [400, {}, ''] # Asana responds with 400 for unknown tasks
    end

    @stubs.post "/api/1.0/tasks/1234/stories" do |env|
      assert_match /#1234/, env[:body]
      [200, {}, '']
    end

    svc = service({'auth_token' => '0000'}, merge_payload)
    assert_nothing_raised { svc.receive_push }
  end

  def test_error_response
    @stubs.post "/api/1.0/tasks/1234/stories" do |env|
      [401, {"Content-Type" => "application/json; charset=UTF-8"}, '{"errors":[{"message":"Not Authorized"}]}']
    end

    svc = service( {'auth_token' => 'bad-token'}, modified_payload)

    begin
      svc.receive_push
    rescue StandardError => e
      assert_equal Service::ConfigurationError, e.class
      assert_equal "Not Authorized", e.message
    end
  end

  def test_asana_exception
    @stubs.post "/api/1.0/tasks/1234/stories" do |env|
      [500, {}, 'Boom!']
    end

    svc = service( {'auth_token' => '0000'}, modified_payload)

    begin
      svc.receive_push
    rescue StandardError => e
      assert_equal Service::ConfigurationError, e.class
      assert_equal "Unexpected Error", e.message
    end
  end

  def service(*args)
    super Service::Asana, *args
  end

  def modified_payload
    pay = payload
    pay['commits'][0]['message'] = "stub git call for Grit#heads test f:15 Case#1234"
    pay['commits'][1]['message'] = "#1234 clean up heads test f:2hrs #1235"
    pay['commits'][2]['message'] = "add more comments about #1235 and #1234 throughout"
    pay
  end

  def merge_payload
    pay = payload
    pay['commits'][0]['message'] = "Merge pull request #42. Fixes Asana task #1234."
    pay
  end

 end
