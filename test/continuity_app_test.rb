require File.expand_path('../helper', __FILE__)

class ContinuityAppTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service({'project_id' => '55'}, 'a' => 1)

    @stubs.post "/github_selfservice/v1/55" do |env|
      assert_match /(^|\&)payload=%7B%22a%22%3A1%7D($|\&)/, env[:body]
      [200, {}, '']
    end

    svc.receive_push

    @stubs.verify_stubbed_calls
  end

  def service(*args)
    super Service::ContinuityApp, *args
  end
end



