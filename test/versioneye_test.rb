# encoding: utf-8

require File.expand_path('../helper', __FILE__)

class VersioneyeTest < Service::TestCase

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push_event
    payload = {'app_name' => "VersionEye"}
    project_id = "987654321"
    api_key = "123456789"
    url = "api/v2/github/hook/#{project_id}"

    svc = service(:push, {'api_key' => api_key, 'project_id' => project_id }, payload)
    @stubs.post url do |env|
      assert_equal "https://www.versioneye.com/api/v2/github/hook/#{project_id}?api_key=#{api_key}", env[:url].to_s
      assert_match 'application/json', env[:request_headers]['content-type']
    end
    svc.receive_event
  end

  private

    def service(*args)
      super Service::Versioneye, *args
    end

end
