require File.expand_path('../helper', __FILE__)

class ReviewableTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_event
    svc = service :pull_request, {}, pull_payload

    @stubs.post "/queues/github.json" do |env|
      assert_equal 'https', env[:url].scheme
      assert_equal 'reviewable.firebaseio.com', env[:url].host
      assert_equal 'application/json', env[:request_headers]['content-type']
      assert_equal pull_payload, JSON.parse(env[:body])
      [200, {}, '']
    end

    svc.receive_event
  end

  def service(event_type, options = {}, *args)
    default_options = {
      'url' => 'https://reviewable.firebaseio.com/queues/github.json', 'content_type' => 'json'
    }
    super Service::Reviewable, event_type, default_options.merge(options), *args
  end
end
