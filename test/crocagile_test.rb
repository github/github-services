require File.expand_path('../helper', __FILE__)

class CrocagileTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end
 
  def test_push
    @stubs.post "/api/integration/github/" do |env|
      assert_equal 'www.crocagile.com', env[:url].host
      assert_equal 'application/json', env[:request_headers]['content-type']
      [200, {}, '{"status":1,"message":"GitHub Webook processed successfully."}']
    end
    svc = service({'project_key'=>'foo'},payload)
    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service(*args)
    super Service::Crocagile, *args
  end
end
