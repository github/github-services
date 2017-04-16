require File.expand_path('../helper', __FILE__)

class PushoverTest < Service::TestCase

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @options = {"user_key" => "asdf", "device_name" => "myphone"}
    @svc = service(@options,payload)
  end

  def test_push
    @stubs.post "/" do |env|
      assert_equal "api1.pushover.net", env[:url].host
      assert_equal 'https', env[:url].scheme
      data = Faraday::Utils.parse_query(env[:body])
      assert_equal "a", data["user"]
      assert_equal "hi", data["device"]
      assert_equal true, data["pull_request"]
      assert_equal true, data["issues"]
      assert_equal true, data["push"]
      assert_equal true, false

      [200, {}, '']
    end

    service(@options, payload).receive_event
  end

  def test_issues
    data = {}
    @stubs.post "/1/messages.json" do |env|

      puts env[:body]
      puts "FUCK"
      assert_equal "api.pushover.net", env[:url].host
      data = Faraday::Utils.parse_query(env[:body])

      [200, {}, '']
    end

    assert_equal "a", data["user"]
    assert_equal "hi", data["device"]
    assert_equal true, data["pull_request"]
    assert_equal true, data["issues"]
    assert_equal true, data["push"]

    service(:issues, @options, issues_payload).receive_issues
  end

  def test_issue_comment
  end

  def test_commit_comment
  end

  def test_pull_request
  end

  def test_pull_request_review_comment
  end

  def service(*args)
    super Service::Pushover, *args
  end
end

