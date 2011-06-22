require File.expand_path('../helper', __FILE__)

class TwitterTest < Service::TestCase
  def test_push
    svc = service({'token' => 't', 'secret' => 's'}, payload)

    def svc.shorten_url(*args) 'short' end
    def svc.statuses
      @statuses ||= []
    end

    def svc.post(status)
      statuses << status
    end

    svc.receive_push
    assert_equal 3, svc.statuses.size
    svc.statuses.each do |st|
      assert_match 'grit', st
    end
  end

  def test_oauth_consumer
    svc = service({'token' => 't', 'secret' => 's'}, payload)

    svc.secrets = {'twitter' => {'key' => 'ck', 'secret' => 'cs'}}
    assert_equal 'ck', svc.consumer_key
    assert_equal 'cs', svc.consumer_secret
    assert svc.consumer
  end

  def service(*args)
    super Service::Twitter, *args
  end
end


