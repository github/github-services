require File.expand_path('../helper', __FILE__)

class AwesomecodeTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_posts_payload
    @stubs.post '/projects/520/builds' do |env|
      assert_equal payload, JSON.parse(Faraday::Utils.parse_query(env[:body])['payload'])
    end
    svc = service({'project_id' => '520'}, payload)
    svc.receive_push
  end

  def test_missing_project_id
    @stubs.post '/projects/520/builds'
    svc = service({'project_id' => ''}, payload)

    assert_raises Service::ConfigurationError do
      svc.receive_push
    end
  end

  def service(*args)
    super Service::Awesomecode, *args
  end
end
