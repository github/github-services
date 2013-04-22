require File.expand_path('../helper', __FILE__)

class ScrumDoTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/hooks/github/slug" do |env|
      assert_equal 'www.scrumdo.com', env[:url].host
      data = Faraday::Utils.parse_query(env[:body])
      assert_equal 'rick',   data['username']
      assert_equal 'monkey', data['password']
      assert data['payload']
      [200, {}, '{}']
    end

    svc = service({
      'username' => 'rick',
      'password' => 'monkey',
      'project_slug' => 'slug'
    }, payload)

    svc.receive_push
  end

  def service(*args)
    super Service::ScrumDo, *args
  end
end




