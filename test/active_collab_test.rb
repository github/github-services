require File.expand_path('../helper', __FILE__)

class ActiveCollabTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/foo/?path_info=projects/1/discussions/add&token=token" do |env|
      assert_equal 'activecollab.com', env[:url].host
      assert_equal 'application/xml', env[:request_headers]["Accept"]
      assert_match /grit/, env[:body]
      [200, {}, '{}']
    end

    svc = service({
      'url'          => 'http://activecollab.com/foo',
      'token'        => 'token',
      'project_id'   => '1',
      'milestone_id' => '2',
      'category_id'  => '3'
    }, payload)

    def svc.shorten_url(*args)
      'short'
    end

    svc.receive_push
  end

  def service(*args)
    super Service::ActiveCollab, *args
  end
end



