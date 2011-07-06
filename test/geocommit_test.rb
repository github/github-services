require File.expand_path('../helper', __FILE__)

class GeoCommitTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service({}, 'a' => 1)

    @stubs.post "/api/github" do |env|
      assert_equal 'application/githubpostreceive+json',
        env[:request_headers]['Content-Type']
      assert_equal 1, JSON.parse(env[:body])['a']
      [200, {}, '']
    end

    svc.receive_push
  end

  def service(*args)
    super Service::GeoCommit, *args
  end
end

