# encoding: utf-8

require File.expand_path('../helper', __FILE__)

class CodeshipTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push_event
    payload = {'app_name' => random_name}
    project_uuid = random_name

    svc = service({'project_uuid' => project_uuid}, payload)
    @stubs.post "/hook/#{project_uuid}" do |env|
      assert_equal "https://www.codeship.io/hook/#{project_uuid}", env[:url].to_s
      assert_match 'application/json', env[:request_headers]['content-type']
      assert_equal payload, JSON.parse(env[:body])
    end
    svc.receive_push
  end

  def test_json_encoding
    payload = {'unicodez' => "rtiaü\n\n€ý5:q"}
    svc = service({'project_uuid' => 'abc'}, payload)
    @stubs.post "/hook/abc" do |env|
      assert_equal payload, JSON.parse(env[:body])
    end
    svc.receive_push
  end

private

  def random_name letters=10
    [*('a'..'z')].shuffle[0..letters-1]
  end

  def service(*args)
    super Service::Codeship, *args
  end
end
