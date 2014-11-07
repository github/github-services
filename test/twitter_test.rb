require File.expand_path('../helper', __FILE__)

class TwitterTest < Service::TestCase
  TWITTER_SHORT_URL_LENGTH_HTTPS = 23

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
      st = st.gsub(/http[^ ]+/, "a"*TWITTER_SHORT_URL_LENGTH_HTTPS) # replace the URL with a substitute for the shortened one
      assert st.length<=140
    end
  end

  # Make sure that GitHub @mentions are injected with a zero-width space
  # so that they don't turn into (potentially unmatching) twitter @mentionds
  def test_mentions
    p = payload
    p['commits'][0]['message']="This commit was done by @sgolemon"
    p['commits'][1]['message']="@sgolemon committed this"
    p['commits'][2]['message']="@sgolemon made a test for @kdaigle"
    svc = service({'token' => 't', 'secret' => 's'}, p)

    def svc.statuses
      @statuses ||= []
    end

    def svc.post(status)
      statuses << status
    end

    svc.receive_push
    assert_equal 3, svc.statuses.size
    svc.statuses.each do |st|
      # Any @ which is not followed by U+200B ZERO WIDTH SPACE
      # is an error
      assert !st.match('@(?!\u200b)')
    end
  end

  def service(*args)
    super Service::Twitter, *args
  end
end
