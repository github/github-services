require File.expand_path('../helper', __FILE__)

class IronMQTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/v1/webhooks/github" do |env|
      form = Faraday::Utils.parse_query(env[:body])
      p form
      assert_equal payload, JSON.parse(form['payload'])
      assert_equal 't', form['token']
      assert_equal '123', form['project_id']
      [200, {}, '']
    end

    token = 'x'
    project_id = '111122223333444455556666'
    svc = service(
        {
            'token' => token,
            'project_id' => project_id
        },
        payload)
    data, payload, resp = svc.receive_event
    assert_equal token, data['token']
    assert_equal project_id, data['project_id']
    assert_equal 200, resp.code
  end

  def service(*args)
    super Service::IronMQ, *args
  end
end
