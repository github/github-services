require File.expand_path('../helper', __FILE__)

class AppHarborTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    application_slug = 'foo'
    token = 'bar'

    @stubs.post "/application/#{application_slug}/build" do |env|
      verify_appharbor_payload(token, env)
    end

    svc = service({'token' => token, 'application_slug' => application_slug}, payload)
    svc.receive_push

    @stubs.verify_stubbed_calls
  end

  def service(*args)
    super Service::AppHarbor, *args
  end

private

  def verify_appharbor_payload(token, env)
    assert_equal token, env[:params]['authorization']
    assert_equal 'application/json', env[:request_headers]['accept']

    branches = JSON.parse(env[:body])['branches']
    assert_equal 1, branches.size

    branch = branches[payload['ref'].sub(/\Arefs\/heads\//, '')]
    assert_not_nil branch
    assert_equal payload['after'], branch['commit_id']
    assert_equal payload['commits'].select{|c| c['id'] == payload['after']}.first['message'], branch['commit_message']
  end
end
