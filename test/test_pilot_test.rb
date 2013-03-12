require File.expand_path('../helper', __FILE__)

class TestPilotTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @svc   = service(data, payload)
  end

  def service(*args)
    super Service::TestPilot, *args
  end

  def data
    {
      'token' => 'TOKEN'
    }
  end

  def test_reads_token_from_data
    assert_equal "TOKEN", @svc.token
  end

  def test_constructs_post_receive_url
    assert_equal 'http://testpilot.me/callbacks/github',
      @svc.test_pilot_url
  end

  def test_posts_payload
    @stubs.post '/callbacks/github' do |env|
      assert_equal env[:params]['token'], @svc.token
      assert_equal payload, JSON.parse(Faraday::Utils.parse_query(env[:body])['payload'])
    end
    @svc.receive_push
  end

  def test_it_raises_an_error_if_no_token_is_supplied
    data = {'token' => ''}
    svc = service(data, payload)
    assert_raises Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_strips_whitespace_from_form_values
    data = {
      'token' => 'TOKEN  '
    }

    svc = service(data, payload)
    assert_equal 'TOKEN', svc.token
  end
end

