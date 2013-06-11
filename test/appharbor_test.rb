require File.expand_path('../helper', __FILE__)

class AppHarborTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_single_slug_push
    test_push 'foo', 'bar'
  end

  def test_multiple_slugs_push
    test_push 'foo,bar', 'baz'
  end

  def service(*args)
    super Service::AppHarbor, *args
  end

private

  def test_push(application_slugs, token)
    application_slugs.split(",").each do |slug|
      @stubs.post "/applications/#{slug}/builds" do |env|
        verify_appharbor_payload(token, env)
      end
    end

    svc = service({'token' => token, 'application_slug' => application_slugs}, payload)
    svc.receive_push

    @stubs.verify_stubbed_calls
  end

  def verify_appharbor_payload(token, env)
    assert_equal "BEARER #{token}", env[:request_headers]['authorization']
    assert_equal 'application/json', env[:request_headers]['accept']

    branches = JSON.parse(env[:body])['branches']
    assert_equal 1, branches.size

    branch = branches[payload['ref'].sub(/\Arefs\/heads\//, '')]
    assert_not_nil branch
    assert_equal payload['after'], branch['commit_id']
    assert_equal payload['commits'].select{|c| c['id'] == payload['after']}.first['message'], branch['commit_message']
  end
end
