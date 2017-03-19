require File.expand_path('../helper', __FILE__)

class FreckleTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    test_subdomain = "test_subdomain"
    test_token = "0123456789abcde"
    test_project = "Test Project"

    data = {
      'subdomain' => test_subdomain,
      'token' => test_token,
      'project' => test_project
    }

    # payload = {'commits'=>[{'id'=>'test'}]}
    svc = service(data, payload)

    @stubs.post "/api/github/commits" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "#{test_subdomain}.letsfreckle.com"
      assert_equal env[:request_headers]['X-FreckleToken'], test_token
      assert_equal env[:request_headers]['X-FreckleProject'], test_project
      #3 entries
      assert_equal 3, body['payload']['commits'].size

      #sends entire commit messages
      assert_equal 'stub git call for Grit#heads test f:15 Case#1', body['payload']['commits'][0]['message']
      assert_equal 'clean up heads test f:2hrs', body['payload']['commits'][1]['message']

      #commit URL valid
      assert_equal 'http://github.com/mojombo/grit/commit/06f63b43050935962f84fe54473a7c5de7977325', body['payload']['commits'][0]['url']

      #author email
      assert_equal 'tom@mojombo.com', body['payload']['commits'][0]['author']['email']

      #timestamp
      assert_equal '2007-10-10T00:11:02-07:00', body['payload']['commits'][0]['timestamp']

      assert_match 'guid-', body['guid']
      assert_equal data, body['config']
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::Freckle
  end
end


