require File.expand_path('../helper', __FILE__)

class PushbulletTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new

    @options = {"api_key" => "a", "device_iden" => "hi"}
  end

  def test_push
    @stubs.post "/api/pushes" do |env|
      check_env env

      expected = {
        "device_iden"=>"hi",
        "type"=>"note",
        "title"=>"rtomayko pushed 3 commits",
         "body"=>"Repo: mojombo/grit\nLatest: add more comments throughout" }

      assert_equal expected, Faraday::Utils.parse_query(env[:body])

      [200, {}, '']
    end

    service(:push, @options, payload).receive_push
  end

  def test_issue
    @stubs.post "/api/pushes" do |env|
      check_env env

      expected = {
        "device_iden"=>"hi",
        "type"=>"note",
        "title"=>"mojombo opened issue #5",
        "body"=>"Repo: mojombo/grit\nIssue: \"booya\"\nboom town"
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
        "device_iden"=>"hi",
        "type"=>"note",
        "title"=>"foo opened pull request #5",
        "body"=>"Repo: mojombo/grit\nPull Request: \"booya\"\nboom town"
      }

      assert_equal expected, Faraday::Utils.parse_query(env[:body])

      [200, {}, '']
    end

    service(:pull_request, @options, pull_payload).receive_pull_request
  end

  def check_env(env)
      assert_equal 'https', env[:url].scheme
      assert_equal "api.pushbullet.com", env[:url].host
      assert_equal "Basic YTo=", env[:request_headers]["Authorization"]
  end

  def service(*args)
    super(Service::Pushbullet, *args)
  end
end