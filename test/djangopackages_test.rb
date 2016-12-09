require File.expand_path('../helper', __FILE__)

class DjangoPackagesTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/packages/github-webhook/" do |env|
      assert_equal 'www.djangopackages.com', env[:url].host
      data = Faraday::Utils.parse_query(env[:body])
      assert_equal 1, JSON.parse(data['payload'])['a']
      [200, {}, '']
    end

    svc = service({"zen" => "test", "hook_id" => "123" }, :a => 1)
    svc.receive_push
  end

  def service(*args)
    super Service::DjangoPackages, *args
  end
end

