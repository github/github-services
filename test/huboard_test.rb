require File.expand_path('../helper', __FILE__)

class HuBoardTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_issues
    @stubs.post "api/site/webhook/issue" do |env|
      assert_equal 'huboard.com', env[:url].host
      assert_equal 'application/x-www-form-urlencoded',
        env[:request_headers]['content-type']
      [200, {}, '']
    end

    service(issues_payload).receive_issues 
  end

  def test_comment
    @stubs.post "api/site/webhook/comment" do |env|
      assert_equal 'huboard.com', env[:url].host
      assert_equal 'application/x-www-form-urlencoded',
        env[:request_headers]['content-type']
      [200, {}, '']
    end

    service(issue_comment_payload).receive_issue_comment
  end

  def service(payload)
    super Service::HuBoard, {}, payload
  end
end

