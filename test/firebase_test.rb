require File.expand_path('../helper', __FILE__)

class FirebaseTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post '/commits.json' do |env|
      assert_equal 'test.firebaseio.com', env[:url].host

      compare = ''
      body = JSON.parse(env[:body])
      payload['commits'].each do |commit|
        if commit['id'] == body['id']
          compare = commit
        end
      end

      assert_equal compare, body
      [200, {}, '']
    end

    svc = service :push, {
      'firebase' => 'https://test.firebaseio.com/commits'
    }, payload
    svc.receive_push
  end

  def test_push_with_secret
    @stubs.post '/commits.json' do |env|
      params = Faraday::Utils.parse_nested_query(env[:url].query)
      assert_equal({'auth' => '12345678abcdefgh'}, params)
    end

    svc = service :push, {
      'firebase' => 'https://test.firebaseio.com/commits',
      'secret' => '12345678abcdefgh'
    }, payload
    svc.receive_push
  end

   def test_push_with_suffix
    @stubs.post '/commits.json' do |env|
      assert_equal 'test.firebaseio.com', env[:url].host
      params = Faraday::Utils.parse_nested_query(env[:url].query)
      assert_equal({'auth' => '12345678abcdefgh'}, params)
      [200, {}, '']
    end

    svc = service :push, {
      'firebase' => 'https://test.firebaseio.com/commits.json',
      'secret' => '12345678abcdefgh'
    }, payload
    svc.receive_push
  end

  def test_without_firebase
    assert_raises Service::ConfigurationError do
      svc = service :push,
        {'firebase' => ''}, payload
      svc.receive_push
    end
  end

  def test_without_https
    assert_raises Service::ConfigurationError do
      svc = service :push,
        {'firebase' => 'http://test.firebaseio.com'}, payload
      svc.receive_push
    end
  end

  def test_invalid_scheme
    assert_raises Service::ConfigurationError do
      svc = service :push,
        {'firebase' => 'ftp://test.firebaseio.com'}, payload
      svc.receive_push
    end
  end

  def service(*args)
    super Service::Firebase, *args
  end
end
