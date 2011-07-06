require File.expand_path('../helper', __FILE__)

class YammerTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service({'group_id' => 'g'}, payload)

    def svc.messages
      @messages ||= []
    end

    def svc.send_message(params)
      messages << params
    end

    def svc.shorten_url(*args)
      'short'
    end

    svc.receive_push

    assert_equal 3, svc.messages.size
    assert_equal %w(g g g), svc.messages.map { |m| m['group_id'] }
  end

  def service(*args)
    super Service::Yammer, *args
  end
end


