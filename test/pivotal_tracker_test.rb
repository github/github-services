require File.expand_path('../helper', __FILE__)

class PivotalTrackerTest < Service::TestCase

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_mismatched_branch
    svc = service({"branch" => "abc"}, payload)
    svc.notifier = Proc.new { raise }
    assert_nothing_raised { svc.receive_push }
  end

  def test_matching_branch
    payload = {"ref" => "refs/heads/master"}
    @stubs.post "/services/v3/github_commits" do |env|
      assert_equal 'www.pivotaltracker.com', env[:url].host
      assert_equal "payload=#{CGI.escape(payload.to_json)}", env[:body]
      [200, {}, '']
    end

    svc = service({"branch" => "master"}, payload)
    svc.receive_push
  end

  def test_no_specified_branch
    @stubs.post "/services/v3/github_commits" do |env|
      assert_equal 'www.pivotaltracker.com', env[:url].host
      assert_equal 'payload=%7B%22a%22%3A1%7D', env[:body]
      [200, {}, '']
    end

    svc = service({}, :a => 1)
    svc.receive_push
  end

  def service(*args)
    super Service::PivotalTracker, *args
  end
end

