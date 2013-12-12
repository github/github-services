require File.expand_path('../helper', __FILE__)

class GitterTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    data = {'token' => "0123456789abcde"}

    svc = service :push, data, push_payload

    @stubs.post "/e/#{data['token']}" do |env|
      body = JSON.parse(env[:body])

      #assert_equal env[:url].host, "webhooks.gitter.im"
      assert_equal env[:request_headers]['X-GitHub-Event'], "push"
      assert_match 'guid-', body['guid']
      assert_equal data, body['config']
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_mute_fork
    data = {'token' => "0123456789abcde", 'mute_fork' => true}

    svc = service :fork, data, basic_payload
    svc.receive_event
    assert @stubs.empty?
  end

  def test_mute_watch
    data = {'token' => "0123456789abcde", 'mute_watch' => true}

    svc = service :watch, data, basic_payload
    svc.receive_event
    assert @stubs.empty?
  end

  def test_mute_comments
    data = {'token' => "0123456789abcde", 'mute_comments' => true}

    svc = service :issue_comment, data, issue_comment_payload
    svc.receive_event
    assert @stubs.empty?
  end

  def test_mute_wiki
    data = {'token' => "0123456789abcde", 'mute_wiki' => true}

    svc = service :gollum, data, gollum_payload
    svc.receive_event
    assert @stubs.empty?
  end

  def service_class
    Service::Gitter
  end
end

