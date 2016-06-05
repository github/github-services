require File.expand_path('../helper', __FILE__)

class IronWorkerTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/v1/webhooks/github" do |env|
      form = Rack::Utils.parse_query(env[:body])
      p form
      assert_equal payload, JSON.parse(form['payload'])
      assert_equal 't', form['token']
      assert_equal '123', form['project_id']
      [200, {}, '']
    end

    token = 'x'
    project_id = '111122223333444455556666'
    code_name = 'fake_code_name'
    svc = service(
        {
            'token' => token,
            'project_id' => project_id,
            'code_name' => code_name
        },
        payload)
    data, payload, resp = svc.receive_event
    assert_equal token, data['token']
    assert_equal project_id, data['project_id']
    assert_equal code_name, data['code_name']
    assert_equal 200, resp.code
  end

  def service(*args)
    super Service::IronWorker, *args
  end
end
