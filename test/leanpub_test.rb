require File.expand_path('../helper', __FILE__)

class LeanpubTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push_from_master
    svc, test_slug, test_api_key = setup_with_branch("master")

    @stubs.post "/#{test_slug}/preview?api_key=#{test_api_key}" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "leanpub.com"
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  # This should never post, so we don't set up any stubs and it fails if it posts.
  def test_push_from_non_master_branch
    svc, _, _ = setup_with_branch("foo")
    svc.receive_event
  end

  def setup_with_branch(branch)
    test_api_key = "123abc"
    test_slug = "myamazingbook"

    data = {
      'api_key' => test_api_key,
      'slug' => test_slug
    }

    payload = {"ref"=>"refs/heads/#{branch}"}
    svc = service(data, payload)
    [svc, test_slug, test_api_key]
  end

  def service_class
    Service::Leanpub
  end
end
