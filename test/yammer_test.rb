require File.expand_path('../helper', __FILE__)

class YammerTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service({'group_id' => 'g'}, payload)

    svc.receive_push

    assert_equal 3, svc.messages.size
    assert_equal %w(g g g), svc.messages.map { |m| m['group_id'] }
  end

  def test_push_non_master_with_master_only
    non_master_payload = payload
    non_master_payload["ref"] = "refs/heads/non-master"
    svc = service({'group_id' => 'g', 'master_only' => 1}, non_master_payload)
    svc.receive_push
    assert_equal 0, svc.messages.size
  end

  def test_push_non_master_without_master_only
    non_master_payload = payload
    non_master_payload["ref"] = "refs/heads/non-master"
    svc = service({'group_id' => 'g', 'master_only' => 0}, non_master_payload)
    svc.receive_push
    assert_equal 3, svc.messages.size
  end

  def service(*args)
    svc = super Service::Yammer, *args

    def svc.messages
      @messages ||= []
    end

    def svc.send_message(params)
      messages << params
    end

    def svc.shorten_url(*args)
      'short'
    end

    svc
  end
end


