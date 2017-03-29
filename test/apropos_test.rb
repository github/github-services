require File.expand_path('../helper', __FILE__)

class WebTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/api/v1/githook/abcdefg01234" do |env|
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal 'www.apropos.io', env[:url].host
      assert_equal payload, JSON.parse(env[:body])
      [200, {}, '{"message":"OK"}']
    end

    svc = service({
        'project_id' => 'abcdefg01234',
        'content_type' => 'json'
        }, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Apropos, *args
  end

end
