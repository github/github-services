require File.expand_path('../helper', __FILE__)

class ShiningPandaTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_post_payload
    @stubs.post '/shiningpanda.org/job/pygments/build' do |env|
      form = Rack::Utils.parse_query(env[:body])
      assert_equal 'github', form['from']
      assert_equal 'PWFm8c2T', form['token']
      assert_equal 'payload_content', JSON.parse(form['payload'])
    end
    svc = service(data, 'payload_content')
    svc.receive_push
  end
  
  def test_requires_workspace
    svc = service :push, { 'job' => 'pygments', 'token' => 'PWFm8c2T' }, 'payload'
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_requires_job
    svc = service :push, { 'workspace' => 'shiningpanda.org', 'token' => 'PWFm8c2T' }, 'payload'
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end
  
  def test_requires_token
    svc = service :push, { 'workspace' => 'shiningpanda.org', 'job' => 'pygments' }, 'payload'
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end
  
  def test_without_parameters
    svc = service(data, payload)
    assert_equal "https://jenkins.shiningpanda.com/shiningpanda.org/job/pygments/build", svc.url
  end

  def test_blank_parameters
    svc = service(data.merge({'parameters' => ''}), payload)
    assert_equal "https://jenkins.shiningpanda.com/shiningpanda.org/job/pygments/build", svc.url
  end
  
  def test_with_parameters
    svc = service(data.merge({'parameters' => 'foo=bar'}), payload)
    assert_equal "https://jenkins.shiningpanda.com/shiningpanda.org/job/pygments/buildWithParameters?foo=bar", svc.url
  end
  
  def test_strip_workspace
    svc = service(data.merge({'workspace' => ' shiningpanda.org '}), payload)
    assert_equal "https://jenkins.shiningpanda.com/shiningpanda.org/job/pygments/build", svc.url
  end

  def test_strip_job
    svc = service(data.merge({'job' => ' pygments '}), payload)
    assert_equal "https://jenkins.shiningpanda.com/shiningpanda.org/job/pygments/build", svc.url
  end

  def test_strip_token
    svc = service(data.merge({'token' => ' PWFm8c2T '}), payload)
    assert_equal "https://jenkins.shiningpanda.com/shiningpanda.org/job/pygments/build?token=PWFm8c2T", svc.url
  end

  def test_strip_token
    @stubs.post '/shiningpanda.org/job/pygments/build' do |env|
      assert_equal 'PWFm8c2T', Rack::Utils.parse_query(env[:body])['token']
    end
    svc = service(data.merge({'token' => ' PWFm8c2T '}), 'payload_content')
    svc.receive_push
  end
  
  def service(*args)
    super Service::ShiningPanda, *args
  end

  def data
    {
      'workspace' => 'shiningpanda.org',
      'job'       => 'pygments',
      'token'     => 'PWFm8c2T',
    }
  end
end

