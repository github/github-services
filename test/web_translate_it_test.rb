require File.expand_path('../helper', __FILE__)

class WebTranslateItTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/api/projects/a/refresh_files" do |env|
      assert_equal 'webtranslateit.com', env[:url].host
      data = Faraday::Utils.parse_nested_query(env[:body])
      assert_equal 1, JSON.parse(data['payload'])['a']
      [200, {}, '']
    end

    svc = service({'api_key' => 'a'}, :a => 1)
    svc.receive_push
  end

  def service(*args)
    super Service::WebTranslateIt, *args
  end
end

