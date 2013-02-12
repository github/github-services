require File.expand_path('../helper', __FILE__)

class IkachanTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  class FakeIkachan < Service::Ikachan
    def shorten_url(*args)
      'short'
    end
  end

  def test_push
    @stubs.post '/join' do |env|
      assert_equal 'http', env[:url].scheme
      assert_equal 'example.jp', env[:url].host
      assert_equal 'application/x-www-form-urlencoded', env[:request_headers]['Content-Type']
      assert_equal '/join', env[:url].path
      assert_equal 'channel=%23r', env[:body]

      [200, {}, '']
    end

    @stubs.post '/notice' do |env|
      assert_equal 'http', env[:url].scheme
      assert_equal 'example.jp', env[:url].host
      assert_equal 'application/x-www-form-urlencoded', env[:request_headers]['Content-Type']
      assert_equal '/notice', env[:url].path
      assert_match /channel=%23r/, env[:body]
      assert_match /message=.+grit.+/, env[:body]
      [200, {}, '']
    end

    svc = service({'url' => 'http://example.jp:4979', 'room' => '#r'}, payload)
    svc.receive_push
  end

  def test_push_without_leading_hash_sign
    @stubs.post '/join' do |env|
      assert_equal 'http', env[:url].scheme
      assert_equal 'example.jp', env[:url].host
      assert_equal 'application/x-www-form-urlencoded', env[:request_headers]['Content-Type']
      assert_equal '/join', env[:url].path
      assert_equal 'channel=%23r', env[:body]

      [200, {}, '']
    end

    @stubs.post '/notice' do |env|
      assert_equal 'http', env[:url].scheme
      assert_equal 'example.jp', env[:url].host
      assert_equal 'application/x-www-form-urlencoded', env[:request_headers]['Content-Type']
      assert_equal '/notice', env[:url].path
      assert_match /channel=%23r/, env[:body]
      assert_match /message=.+grit.+/, env[:body]
      [200, {}, '']
    end

    svc = service({'url' => 'http://example.jp:4979', 'room' => 'r'}, payload)
    svc.receive_push
  end

  def test_push_with_multiple_rooms
    @stubs.post '/join' do |env|
      assert_equal 'http', env[:url].scheme
      assert_equal 'example.jp', env[:url].host
      assert_equal 'application/x-www-form-urlencoded', env[:request_headers]['Content-Type']
      assert_equal '/join', env[:url].path
      assert_match /channel=%23(foo|bar|baz)/, env[:body]

      [200, {}, '']
    end

    @stubs.post '/notice' do |env|
      assert_equal 'http', env[:url].scheme
      assert_equal 'example.jp', env[:url].host
      assert_equal 'application/x-www-form-urlencoded', env[:request_headers]['Content-Type']
      assert_equal '/notice', env[:url].path
      assert_match /channel=%23(foo|bar|baz)/, env[:body]
      assert_match /message=.+grit.+/, env[:body]
      [200, {}, '']
    end

    svc = service({'url' => 'http://example.jp:4979', 'room' => 'foo, #bar, baz'}, payload)
    svc.receive_push
  end

  def service(*args)
    super FakeIkachan, *args
  end

end
