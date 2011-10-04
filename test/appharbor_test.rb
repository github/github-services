require File.expand_path('../helper', __FILE__)

class AppHarborTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    application_slug = "foo"
    token = "bar"

    @stubs.post "/application/#{application_slug}/build" do |env|
      assert_equal token, env[:params]["authorization"]
      assert_equal 'application/json', env[:request_headers]["accept"]

      branches = JSON.parse(env[:body])['branches']
      assert_equal 1, branches.size
    end

    svc = service({"token" => token, "application_slug" => application_slug}, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::AppHarbor, *args
  end
end
