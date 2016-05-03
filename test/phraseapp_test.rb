require File.expand_path('../helper', __FILE__)

class PhraseappTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    test_auth_token = "footoken"

    data = {
      "auth_token" => test_auth_token
    }

    payload = {'commits'=>[{'id'=>'test'}]}
    svc = service(data, payload)

    @stubs.post "/api/v1/hooks/github" do |env|
      body = JSON.parse(env[:body])
      
      assert_equal("phraseapp.com", env[:url].host)
      assert_equal("post", env[:method].to_s)
      [200, {}, '']
    end

    svc.receive_push
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::Phraseapp
  end
end

