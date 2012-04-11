require File.expand_path('../helper', __FILE__)

class GroupTalentTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = "/github/receive_push/abc"
    @stubs.post url do |env|
      assert_equal "payload=%22payload%22", env[:body]
      [200, {}, '']
    end

    svc = service :push, {:token => 'abc'}, 'payload'
    svc.receive
  end

  def service(*args)
    super Service::GroupTalent, *args
  end
end

