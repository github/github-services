require File.expand_path('../helper', __FILE__)

class ServiceTest < Service::TestCase
  class TestService < Service
    def receive_push
    end
  end

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @service = service(:push, 'data', 'payload')
  end

  def test_receive_valid_event
    assert TestService.receive :push, {}, {}

    assert_raise ArgumentError do
      TestService.receive :star, {}, {}
    end
  end

  def test_url_shorten
    url = "http://github.com"
    bitly = "/shorten?apiKey=%s&login=%s&longUrl=%s&version=%s" % [
      'R_261d14760f4938f0cda9bea984b212e4', 'github', 'http%3A%2F%2Fgithub.com', '2.0.1' ]
    @stubs.get bitly do
      [200, {}, {
        'errorCode' => 0,
        'results' => {
          url => {'shortUrl' => 'short'}
        }
      }.to_json]
    end

    assert_equal 'short', @service.shorten_url(url)
  end

  def service(*args)
    super TestService, *args
  end
end
