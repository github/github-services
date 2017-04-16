require File.expand_path('../helper', __FILE__)

class ReviewNinjaTest < Service::TestCase
  include Service::HttpTestMethods

  def test_pull_request
    test_token = '0123456789abcde'
    test_domain = 'http://review.ninja'

    data = {
      'token' => test_token,
      'domain' => test_domain
    }

    payload = {
      'action' => 'opened', 
      'number' => 1, 
      'pull_request' => {
        'head' => {'sha'=> '1234abcd'}
      },
      'repository' => {
        'id' => 1234,
        'name' => 'foo',
        'owner' => {'login' => 'reviewninja'}
      }
    }

    svc = service(:pull_request, data, payload)

    @stubs.post '/github/service' do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].scheme, 'http'
      assert_equal env[:url].host, 'review.ninja'
      assert_equal env[:request_headers]['X-GitHub-Event'], 'pull_request'
      assert_equal 'opened', body['payload']['action']
      assert_equal 1, body['payload']['number']
      assert_equal '1234abcd', body['payload']['pull_request']['head']['sha']
      assert_equal 1234, body['payload']['repository']['id']
      assert_equal 'foo', body['payload']['repository']['name']
      assert_equal 'reviewninja', body['payload']['repository']['owner']['login']
      assert_equal data, body['config']
      assert_equal 'pull_request', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_issues
    test_token = '0123456789abcde'
    test_domain = 'http://review.ninja'

    data = {
      'token' => test_token,
      'domain' => test_domain
    }

    payload = {
      'action' => 'opened', 
      'number' => 2, 
      'milestone' => {
        'number' => 10
      },
      'repository' => {
        'id' => 1234,
        'name' => 'foo',
        'owner' => {'login' => 'reviewninja'}
      }
    }

    svc = service(:issues, data, payload)

    @stubs.post '/github/service' do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].scheme, 'http'
      assert_equal env[:url].host, 'review.ninja'
      assert_equal env[:request_headers]['X-GitHub-Event'], 'issues'
      assert_equal 'opened', body['payload']['action']
      assert_equal 2, body['payload']['number']
      assert_equal 10, body['payload']['milestone']['number']
      assert_equal 1234, body['payload']['repository']['id']
      assert_equal 'foo', body['payload']['repository']['name']
      assert_equal 'reviewninja', body['payload']['repository']['owner']['login']
      assert_equal data, body['config']
      assert_equal 'issues', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_issue_comment
    test_token = '0123456789abcde'
    test_domain = 'https://review.ninja'

    data = {
      'token' => test_token,
      'domain' => test_domain
    }

    payload = {
      'action' => 'created', 
      'number' => 3,
      'repository' => {
        'id' => 1234,
        'name' => 'foo',
        'owner' => {'login' => 'reviewninja'}
      }
    }

    svc = service(:issue_comment, data, payload)

    @stubs.post '/github/service' do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].scheme, 'https'
      assert_equal env[:url].host, 'review.ninja'
      assert_equal env[:request_headers]['X-GitHub-Event'], 'issue_comment'
      assert_equal 'created', body['payload']['action']
      assert_equal 3, body['payload']['number']
      assert_equal 1234, body['payload']['repository']['id']
      assert_equal 'foo', body['payload']['repository']['name']
      assert_equal 'reviewninja', body['payload']['repository']['owner']['login']
      assert_equal data, body['config']
      assert_equal 'issue_comment', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_status
    test_token = '0123456789abcde'
    test_domain = 'https://review.ninja'

    data = {
      'token' => test_token,
      'domain' => test_domain
    }

    payload = {
      'sha' => 'asdf1234',
      'state' => 'pending',
      'repository' => {
        'id' => 1234,
        'name' => 'foo',
        'owner' => {'login' => 'reviewninja'}
      }
    }

    svc = service(:status, data, payload)

    @stubs.post '/github/service' do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].scheme, 'https'
      assert_equal env[:url].host, 'review.ninja'
      assert_equal env[:request_headers]['X-GitHub-Event'], 'status'
      assert_equal 'asdf1234', body['payload']['sha']
      assert_equal 'pending', body['payload']['state']
      assert_equal 1234, body['payload']['repository']['id']
      assert_equal 'foo', body['payload']['repository']['name']
      assert_equal 'reviewninja', body['payload']['repository']['owner']['login']
      assert_equal data, body['config']
      assert_equal 'status', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::ReviewNinja
  end
end

