require File.expand_path('../helper', __FILE__)

class AppHarborTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    application_slug = 'foo'
    token = 'bar'

    @stubs.post "/applications/#{application_slug}/builds" do |env|
      assert_equal 'application/json', env[:request_headers]['accept']
      assert_equal "BEARER #{token}", env[:request_headers]['authorization']

      branches = JSON.parse(env[:body])['branches']
      assert_equal 1, branches.size

      branch = branches[payload['ref'].sub(/\Arefs\/heads\//, '')]
      assert_not_nil branch
      assert_equal payload['after'], branch['commit_id']
      assert_equal payload['commits'].select{|c| c['id'] == payload['after']}.first['message'], branch['commit_message']
    end

    svc = service({'token' => token, 'application_slug' => application_slug}, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::AppHarbor, *args
  end
end
