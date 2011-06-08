require File.expand_path('../helper', __FILE__)

class CommitifyTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service({'private_key' => 'abc'}, 'a' => 1)

    @stubs.post "/commit" do |env|
      assert_match "key=abc", env[:body]
      [200, {}, '']
    end

    svc.receive_push

    @stubs.verify_stubbed_calls
  end

  def service(*args)
    super Service::Commitify, *args
  end
end



