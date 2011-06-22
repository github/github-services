require File.expand_path('../helper', __FILE__)

class MantisBTTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/abc/plugin.php" do |env|
      assert_equal 'abc.com', env[:url].host
      assert_equal 'Source/checkin', env[:params]['page']
      assert_equal 'key', env[:params]['api_key']
      assert_match 'payload=%7B%22a%22%3A1%7D', env[:body]
      [200, {}, '']
    end

    svc = service(
      {'url' => 'http://abc.com/abc/', 'api_key' => 'key'},
      :a => 1)
    svc.receive_push
  end

  def service(*args)
    super Service::MantisBT, *args
  end
end

