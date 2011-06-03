require File.expand_path('../helper', __FILE__)

class BoxcarTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service :push, {'subscribers' => 'abc'}, {'a' => 1}
    svc.secrets = {'boxcar' => {'apikey' => 'key'}}

    @stubs.post "/github/key" do |env|
      assert_match /(^|\&)emails=abc($|\&)/, env[:body]
      assert_match /(^|\&)payload=%7B%22a%22%3A1%7D($|\&)/, env[:body]
      [200, {}, '']
    end

    svc.receive_push

    @stubs.verify_stubbed_calls
  end

  def service(*args)
    super Service::Boxcar, *args
  end
end


