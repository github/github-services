require File.expand_path('../helper', __FILE__)

class DatadogTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @data = {
      'api_key' => '123',
      'tags' => 'environment:dev, test,  web:cluster1',
    }
  end

  def test_push
    assert '123', @data['api_key']
    assert_includes @data['tags'], 'web:cluster1'

    @stubs.post '/api/v1/events' do |env|
      assert_equal 'app.datadoghq.com', env[:url].host

      assert_match 'Latest Commit by Tom Preston-Werner', env[:body]
      assert_match 'web:cluster1', env[:body]

      [202, {}, '']
    end

    svc = service(@data, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Datadog, *args
  end
end
