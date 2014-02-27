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
    @stubs.post "/api/pushes" do |env|
      check_env env

      expected = {
        "device_iden"=>"udhfWdjz4gRNO0Aq",
        "type"=>"note",
        "title"=>"rtomayko pushed 3 commits...",
        "body"=>
        "To mojombo/grit:\nL[grit/master] stub git call for Grit#heads test f:15 Case#1 - Tom Preston-Werner\n[grit/master] clean up heads test f:2hrs - Tom Preston-Werner\n[grit/master] add more comments throughout - Tom Preston-Werner"
      }

      assert_equal expected, Faraday::Utils.parse_query(env[:body])

      [200, {}, '']
    end

    service(:push, @options, payload).receive_push
  end

  def test_issue
    @stubs.post "/api/pushes" do |env|
      check_env env

      expected = {
        "device_iden"=>"udhfWdjz4gRNO0Aq",
        "type"=>"note",
        "title"=>"defunkt opened issue #5",
        "body"=>"In mojombo/grit: \"booya\"\nboom town"
      }

      assert_equal expected, Faraday::Utils.parse_query(env[:body])

      [200, {}, '']
    end

    service(:issue, @options, issues_payload).receive_issue
  end

  def test_pull_request
    @stubs.post "/api/pushes" do |env|
      check_env env

      expected = {
        "device_iden"=>"udhfWdjz4gRNO0Aq",
        "type"=>"note",
        "title"=>"defunkt opened pull request #5",
        "body"=>"In mojombo/grit: \"booya\" (master...feature)\nboom town"
      }

      assert_equal expected, Faraday::Utils.parse_query(env[:body])

      [200, {}, '']
    end

    service(:pull_request, @options, pull_payload).receive_pull_request
  end

  def check_env(env)
      assert_equal 'https', env[:url].scheme
      assert_equal "api.pushbullet.com", env[:url].host
      assert_equal "Basic ZTRmMjM1YTM4NTFnMzk2ZDgwMTc3MmI1MDQ4OTgxNDA6", env[:request_headers]["Authorization"]
  end

  def service(*args)
    super(Service::Pushbullet, *args)
  end
end