require File.expand_path('../helper', __FILE__)

class CopperEggTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/v2/annotations.json" do |env|
      assert_match "api_key=beef", env[:body]
      assert_match "tag=taggy", env[:body]
      [200, {}, '']
    end

    svc = service(
      {'api_key' => 'beef', 'tag' => 'taggy'}, 'a' => 1)
    svc.receive_push
  end

  def service(*args)
    super Service::HipChat, *args
  end
end

