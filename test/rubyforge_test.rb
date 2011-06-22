require File.expand_path('../helper', __FILE__)

class RubyforgeTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service({'groupid' => 'g'}, payload)
    def svc.news
      @news ||= []
    end

    def svc.post_news(*args)
      news << args
    end

    svc.receive_push
    assert news = svc.news.shift
    assert_equal 'g', news[0]
    assert_match '06f63b43050935962f84fe54473a7c5de7977325', news[1]
    assert_match 'stub git call', news[2]
  end

  def service(*args)
    super Service::Rubyforge, *args
  end
end

