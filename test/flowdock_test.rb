require File.expand_path('../helper', __FILE__)

class FlowdockTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/v1/git" do |env|
      assert_match /(^|\&)payload=%7B%22a%22%3A1%7D($|\&)/, env[:body]
      assert_match "token=t", env[:body]
      [200, {}, '']
    end

    svc = service :push,
      {'token' => 't'}, {'a' => 1}
    svc.receive_push
  end

  def service(*args)
    super Service::Flowdock, *args
  end
end

