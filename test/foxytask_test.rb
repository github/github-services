require File.expand_path('../helper', __FILE__)

class FoxytaskTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_issues
    @stubs.post "/webhook" do |env|
      assert_equal 'www.foxytask.com', env[:url].host
      assert_equal 'application/json',
        env[:request_headers]['content-type']
      [200, {}, '']
    end

    svc = service :push, payload
    svc.receive_issues
  end

  def test_issue_comment
    @stubs.post "/webhook" do |env|
      assert_equal 'www.foxytask.com', env[:url].host
      assert_equal 'application/json',
        env[:request_headers]['content-type']
      [200, {}, '']
    end

    svc = service :push, payload
    svc.receive_issue_comment
  end

  def service(*args)
    super Service::Foxytask, *args
  end
end
