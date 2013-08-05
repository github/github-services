require File.expand_path('../helper', __FILE__)

class HakiriTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    test_project_id = '1'
    test_token = '0123456789abcde'

    data = {
        'project_id' => test_project_id,
        'token' => test_token
    }

    payload = { 'commits' => [{ 'id'=>'test' }] }
    svc = service(data, payload)

    @stubs.post "/projects/#{test_project_id}/repositories/github_push?repo_token=#{test_token}" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, 'www.hakiriup.com'
      assert_equal 'test', body['payload']['commits'][0]['id']
      assert_equal data, body['config']
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::Hakiri
  end
end

