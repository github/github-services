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
  
  def test_tweet_length
    p = payload
    p['commits'][0]['message']="This is a very long message specifically designed to test the new behaviour of the twitter service hook with extremely long tweets. As should be happening now."
    svc = service({'token' => 't', 'secret' => 's'}, p)
    
    def svc.statuses
      @statuses ||= []
    end

    def svc.post(status)
      statuses << status
    end

    svc.receive_push
    
    svc.statuses.each do |st|
      st = st.gsub(/http[^ ]+/, "a"*21) # replace the URL with a substitute for the shortened one
      assert st.length<=140
    end
  end

  def service(*args)
    super Service::Twitter, *args
  end
end


