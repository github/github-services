require File.expand_path('../helper', __FILE__)

class KatoTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    payload_example = push_payload() # from helper
    svc = service(svc_data(), payload_example)

    stub_post_for_payload("push", payload_example)
    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_ignore_commits_silences_push_events
    svc = service(:push, svc_data('ignore_commits' => true), push_payload)
    assert_nothing_raised { svc.receive_event }
  end

  def test_ignore_commits_will_not_silence_other_events
    stub_post_for_payload("commit_comment", commit_comment_payload)
    svc = service(:commit_comment, svc_data('ignore_commits' => true), commit_comment_payload)
    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_ignore_commit_comments_silences_commit_comment_events
    svc = service(:commit_comment, svc_data('ignore_commit_comments' => true), commit_comment_payload)
    assert_nothing_raised { svc.receive_event }
  end

  def test_ignore_commit_comments_will_not_silence_other_events
    stub_post_for_payload("push", push_payload)
    svc = service(:push, svc_data('ignore_commit_comments' => true), push_payload)
    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_ignore_issues_silences_issue_events
    svc = service(:issues, svc_data('ignore_issues' => true), issues_payload)
    assert_nothing_raised { svc.receive_event }
  end

  def test_ignore_issues_will_not_silence_other_events
    stub_post_for_payload("push", push_payload)
    svc = service(:push, svc_data('ignore_issues' => true), push_payload)
    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_ignore_issue_comments_silences_issue_comment_events
    svc = service(:issue_comment, svc_data('ignore_issue_comments' => true), issue_comment_payload)
    assert_nothing_raised { svc.receive_event }
  end

  def test_ignore_issue_comments_will_not_silence_other_events
    stub_post_for_payload("push", push_payload)
    svc = service(:push, svc_data('ignore_issue_comments' => true), push_payload)
    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_ignore_pull_requests_silences_pull_request_events
    svc = service(:pull_request, svc_data('ignore_pull_requests' => true), pull_payload)
    assert_nothing_raised { svc.receive_event }
  end

  def test_ignore_pull_requests_will_not_silence_other_events
    stub_post_for_payload("push", push_payload)
    svc = service(:push, svc_data('ignore_pull_requests' => true), push_payload)
    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_ignore_pull_request_review_comments_silences_pull_request_comments_events
    svc = service(:pull_request_review_comment, svc_data('ignore_pull_request_review_comments' => true), pull_request_review_comment_payload)
    assert_nothing_raised { svc.receive_event }
  end

  def test_ignore_pull_request_review_comments_will_not_silence_other_events
    stub_post_for_payload("push", push_payload)
    svc = service(:push, svc_data('ignore_pull_request_review_comments' => true), push_payload)
    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_ignore_wiki_page_updates_silences_wiki_events
    svc = service(:gollum, svc_data('ignore_wiki_page_updates' => true), gollum_payload)
    assert_nothing_raised { svc.receive_event }
  end

  def test_ignore_wiki_page_updates_will_not_silence_other_events
    stub_post_for_payload("push", push_payload)
    svc = service(:push, svc_data('ignore_wiki_page_updates' => true), push_payload)
    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::Kato
  end

  def host
    "api.kato.im"
  end

  def path
    "/rooms/ca584f3e2143a0c3eae7a89485aa7f634589ceb39c972361bdefe348812794b1/github"
  end

  def svc_data(extra_data = {})
    data = {
      'webhook_url' => "http://" + host + path
    }
    data.merge extra_data
  end

  def stub_post_for_payload(event, payload_example)
    @stubs.post path do |env|

      assert_equal host, env[:url].host
      assert_equal 'application/json', env[:request_headers]['Content-type']

      data = JSON.parse(env[:body])
      assert_equal event, data['event']
      assert_equal payload_example, data['payload']
      [200, {}, '']
    end
  end
end
