require File.expand_path('../helper', __FILE__)

class PushoverTest < Service::TestCase

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service({"user_key" => "a", "device_name" => "hi"}, payload)

    def svc.shorten_url(*args)
      "short"
    end

    @stubs.post "/1/messages.json" do |env|
      assert_equal "api.pushover.net", env[:url].host
      data = Faraday::Utils.parse_query(env[:body])
      assert_equal "a", data["user"]
      assert_equal "hi", data["device"]
      assert_equal true, data["pull_request"]
      assert_equal true, data["issues"]
      assert_equal true, data["push"]
      [200, {}, '']
    end

    svc.receive_event
  end

  def test_issues
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

