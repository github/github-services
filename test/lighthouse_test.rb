require File.expand_path('../helper', __FILE__)

class LighthouseTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/projects/1/changesets.xml" do |env|
      assert_equal 'application/xml', env[:request_headers]['Content-Type']
      assert_equal 's.lighthouseapp.com', env[:url].host
      [200, {}, '']
    end

    svc = service(
      {'subdomain' => 's', 'project_id' => '1'}, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Lighthouse, *args
  end
end

