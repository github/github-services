require File.expand_path('../helper', __FILE__)

class HipChatTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/v1/webhooks/github" do |env|
      form = Faraday::Utils.parse_query(env[:body])
      assert_equal simple_payload, JSON.parse(form['payload'])
      assert_equal 'a', form['auth_token']
      assert_equal 'r', form['room_id']
      [200, {}, '']
    end

    svc = service({'auth_token' => 'a', 'room' => 'r'}, simple_payload)
    svc.receive_event
  end

  def test_quiet_fork_silences_fork_events
    [:fork, :fork_apply].each do |fork_event|
      svc = service(fork_event,
        default_data_plus('quiet_fork' => '1'), simple_payload )
      assert_nothing_raised { svc.receive_event }
    end
  end

  def test_quiet_fork_will_not_silence_other_events
    stub_simple_post
    svc = service(default_data_plus('quiet_fork' => '1'), simple_payload)
    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_quiet_watch_silences_watch_events
    svc = service(:watch,
      default_data_plus('quiet_watch' => '1'), simple_payload)
    assert_nothing_raised { svc.receive_event }
  end

  def test_quiet_watch_will_not_silence_other_events
    stub_simple_post
    svc = service(default_data_plus('quiet_watch' => '1'), simple_payload)
    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_quiet_comments_silences_comment_events
    [:commit_comment, :issue_comment].each do |comment_event|
      svc = service(comment_event,
        default_data_plus('quiet_comments' => '1'), simple_payload )
      assert_nothing_raised { svc.receive_event }
    end
  end

  def test_quiet_comments_will_not_silence_other_events
    stub_simple_post
    svc = service(default_data_plus('quiet_comments' => '1'), simple_payload)
    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_quiet_wiki_silences_wiki_events
    svc = service(:gollum,
      default_data_plus('quiet_wiki' => '1'), simple_payload )
    assert_nothing_raised { svc.receive_event }
  end

  def test_quiet_wiki_will_not_silence_other_events
    stub_simple_post
    svc = service(default_data_plus('quiet_wiki' => '1'), simple_payload)
    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service(*args)
    super Service::HipChat, *args
  end

  def simple_payload
    {'a' => 1, 'ref' => 'refs/heads/master'}
  end

  def stub_simple_post
    @stubs.post "/v1/webhooks/github" do |env|
      [200, {}, '']
    end
  end

  def default_data_plus(new_data)
    {'auth_token' => 'a', 'room' => 'r'}.merge(new_data)
  end
end

