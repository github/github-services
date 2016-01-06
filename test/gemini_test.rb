require File.expand_path('../helper', __FILE__)

class GeminiTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/gemini/api/github/commit" do |env|
      assert_equal 'localhost', env[:url].host
      assert_equal 'application/json', env[:request_headers]['content-type']
      [200, {}, '']
    end

    config = {'server_url' => 'http://localhost/gemini',
      'api_key' => '43904539-01DD-48DF-98F3-C887DE833C3H'}

    svc = service(config, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Gemini, *args
  end
end
