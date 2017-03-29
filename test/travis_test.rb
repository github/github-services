require File.expand_path('../helper', __FILE__)

class TravisTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @svc   = service(basic_config, push_payload)
    @svc.delivery_guid = 'guid-123'
  end

  def test_reads_user_from_config
    assert_equal 'kronn', @svc.user
  end

  def test_reads_token_from_config
    assert_equal "5373dd4a3648b88fa9acb8e46ebc188a", @svc.token
  end

  def test_reads_domain_from_config
    svc = service(basic_config.merge({ 'domain' => 'http://example.com' }), payload)
    assert_equal "example.com", svc.domain
  end

  def test_keeps_https_scheme
    svc = service(basic_config.merge({ 'domain' => 'https://example.com' }), payload)
    assert_equal 'https', svc.scheme
  end

  def test_reads_default_domain_when_not_in_config
    assert_equal "notify.travis-ci.org", @svc.domain
  end

  def test_constructs_post_receive_url
    assert_equal 'http://notify.travis-ci.org', @svc.travis_url
  end

  def test_posts_payload
    @stubs.post '/' do |env|
      assert_equal 'http://notify.travis-ci.org', env[:url].to_s
      assert_equal basic_auth('kronn', '5373dd4a3648b88fa9acb8e46ebc188a'),
        env[:request_headers]['authorization']
      assert_equal 'push', env[:request_headers]['x-github-event']
      assert_equal 'guid-123', env[:request_headers]['x-github-guid']
      assert_equal payload, JSON.parse(Faraday::Utils.parse_query(env[:body])['payload'])
    end
    @svc.receive_event
  end

  def test_pull_request_payload
    @svc = service(:pull_request, basic_config, pull_payload)
    @stubs.post '/' do |env|
      assert_equal 'http://notify.travis-ci.org', env[:url].to_s
      assert_equal basic_auth('kronn', '5373dd4a3648b88fa9acb8e46ebc188a'),
        env[:request_headers]['authorization']
      assert_equal 'pull_request', env[:request_headers]['x-github-event']
      assert_equal pull_payload, JSON.parse(Faraday::Utils.parse_query(env[:body])['payload'])
    end
    @svc.receive_event
  end

  def test_pull_request_payload_without_username
    data = {
      'user' => '',
      'token' => '5373dd4a3648b88fa9acb8e46ebc188a'
    }
    svc = service(:pull_request, blank_user_config, pull_payload)

    assert_equal pull_payload['repository']['owner']['login'], svc.user
    assert_equal '5373dd4a3648b88fa9acb8e46ebc188a', svc.token
  end

  def test_strips_whitespace_from_form_values
    data = {
      'user' => 'kronn  ',
      'token' => '5373dd4a3648b88fa9acb8e46ebc188a  ',
      'domain' => 'my-travis-ci.heroku.com   '
    }

    svc = service(data, payload)

    assert_equal 'kronn', svc.user
    assert_equal '5373dd4a3648b88fa9acb8e46ebc188a', svc.token
    assert_equal 'my-travis-ci.heroku.com', svc.domain
  end

  def test_handles_blank_strings_without_errors
    data = {
      'user' => '',
      'token' => '5373dd4a3648b88fa9acb8e46ebc188a',
      'domain' => ''
    }

    svc = service(data, payload)

    assert_equal 'mojombo', svc.user
    assert_equal '5373dd4a3648b88fa9acb8e46ebc188a', svc.token
    assert_equal 'notify.travis-ci.org', svc.domain
    assert_equal 'http', svc.scheme
  end

  def test_infers_user_from_repo_data
    svc = service(basic_config.reject{ |key,v| key == 'user' }, payload)
    assert_equal "mojombo", svc.user
  end

  def test_defaults_to_http_scheme
    assert_equal 'http', @svc.scheme
  end

  def test_defaults_to_pings_travis_ci_domain
    svc = service(basic_config.reject{ |key,v| key == 'domain' }, payload)
    assert_equal "notify.travis-ci.org", svc.domain
  end

  def service(*args)
    super Service::Travis, *args
  end

  def basic_config
    {
      'user' => 'kronn',
      'token' => '5373dd4a3648b88fa9acb8e46ebc188a'
    }
  end

  def blank_user_config
    {
      'user' => '',
      'token' => '5373dd4a3648b88fa9acb8e46ebc188a'
    }
  end
end

