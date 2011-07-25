require File.expand_path('../helper', __FILE__)

class PlanboxTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/api/github_commits" do |env|
      assert_equal 'www.planbox.com', env[:url].host
      assert_match 'payload=%7B%22a%22%3A1%7D', env[:body]
      [200, {}, '']
    end

    svc = service({}, :a => 1)
    svc.receive_push
  end

  def service(*args)
    super Service::Planbox, *args
  end
end

