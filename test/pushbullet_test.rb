require File.expand_path('../helper', __FILE__)

class PushbulletTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new

    @options = {
      "api_key" => "e4f235a3851g396d801772b504898140",
      "device_iden" => "udhfWdjz4gRNO0Aq"
    }
  end

  def test_push
    stub_request "push"
    service(:push, @options, payload).receive_event
  end

  def test_push_no_device_iden
    @options["device_iden"] = ""
    stub_request "push"
    service(:push, @options, payload).receive_event
  end

  def test_issue
    stub_request "issues"
    service(:issues, @options, issues_payload).receive_event
  end

  def test_pull_request
    stub_request "pull_request"
    service(:pull_request, @options, pull_payload).receive_event
  end

  def stub_request(event)
    @stubs.post "/github" do |env|
      assert_equal 'https', env[:url].scheme
      assert_equal "webhook.pushbullet.com", env[:url].host
      body = JSON.parse(env[:body])
      assert_equal event, body['event']
      assert_equal @options, body['config']
      [200, {}, '']
    end
  end

  def service(*args)
    super(Service::Pushbullet, *args)
  end
end
