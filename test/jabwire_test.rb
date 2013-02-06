require File.expand_path('../helper', __FILE__)

class JabwireTest < Service::TestCase

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @svc   = service(data, payload)
  end

  def test_reads_apikey_from_data
    assert_equal "5373dd4a3648b88fa9acb8e46ebc188a", @svc.apikey
  end

  def test_reads_project_id_from_data
    assert_equal "1000", @svc.project_id
  end

  def test_strips_whitespace_from_token
    svc = service({'apikey' => '5373dd4a3648b88fa9acb8e46ebc188a  '}, payload)
    assert_equal '5373dd4a3648b88fa9acb8e46ebc188a', svc.apikey
  end

  def test_posts_payload
    @stubs.post '/projects/1000/webhook?apikey=5373dd4a3648b88fa9acb8e46ebc188a' do |env|
      assert_equal 'https', env[:url].scheme
      assert_equal 'www.jabwire.com', env[:url].host
      assert_equal payload, JSON.parse(Rack::Utils.parse_query(env[:body])['payload'])
    end

    @svc.receive_push
  end

private

  def service(*args)
    super Service::Jabwire, *args
  end

  def data
    { 
      'apikey' => '5373dd4a3648b88fa9acb8e46ebc188a',
      'project_id' => 1000
    }
  end

end
