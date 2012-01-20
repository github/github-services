require File.expand_path('../helper', __FILE__)

class TalkerTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push_with_digest_on
    expect_message_posting

    svc = service({'digest' => '1'}, push_payload)
    svc.receive_push
  end

  def test_push_with_digest_off_and_several_distinct_commits
    expect_message_posting

    payload = push_payload
    assert payload['commits'].size > 1

    svc = service({'digest' => '0'}, payload)
    svc.receive_push
  end

  def test_push_with_digest_off_and_a_single_distinct_commit
    expect_message_posting

    payload = push_payload
    payload['commits'] = [payload['commits'].first]

    svc = service({'digest' => '0'}, payload)
    svc.receive_push
  end

  def service(options, *args)
    default_options = {'url' => 'https://s.talkerapp.com/room/1', 'token' => 't'}
    super Service::Talker, default_options.merge(options), *args
  end

  private
    def expect_message_posting
      @stubs.post "/room/1/messages.json" do |env|
        assert_equal 's.talkerapp.com', env[:url].host
        assert_equal 't', env[:request_headers]['x-talker-token']
        data = Rack::Utils.parse_nested_query(env[:body])
        assert data.key?('message')
        [200, {}, '']
      end
    end
end

