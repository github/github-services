require File.expand_path('../helper', __FILE__)

class ShiningPandaTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_receive_push_without_parameters
    @stubs.post '/shiningpanda.org/job/pygments/build' do |env|
      form = Faraday::Utils.parse_query(env[:body])
      assert_equal 'PWFm8c2T', form['token']
      assert_equal 'Triggered by a push of omansion to master (commit: 83d9205e73c25092ce7cb7ce530d2414e6d068cb)', form['cause']
    end
    svc = service(data, payload)
    svc.receive_push
  end

  def test_receive_push_with_parameters
    @stubs.post '/shiningpanda.org/job/pygments/buildWithParameters' do |env|
      form = Faraday::Utils.parse_query(env[:body])
      assert_equal 'PWFm8c2T', form['token']
      assert_equal 'Triggered by a push of omansion to master (commit: 83d9205e73c25092ce7cb7ce530d2414e6d068cb)', form['cause']
      assert_equal 'bar', form['foo']
    end
    svc = service(data.merge({'parameters' => 'foo=bar'}), payload)
    svc.receive_push
  end

  def test_receive_push_branch_match
    @stubs.post '/shiningpanda.org/job/pygments/build' do |env|
      form = Faraday::Utils.parse_query(env[:body])
      assert_equal 'PWFm8c2T', form['token']
      assert_equal 'Triggered by a push of omansion to dev (commit: 83d9205e73c25092ce7cb7ce530d2414e6d068cb)', form['cause']
    end
    svc = service(data.merge({'branches' => 'dev'}), payload.merge({'ref' => 'refs/head/dev'}))
    svc.receive_push
  end

  def test_receive_push_branches_match
    @stubs.post '/shiningpanda.org/job/pygments/build' do |env|
      form = Faraday::Utils.parse_query(env[:body])
      assert_equal 'PWFm8c2T', form['token']
      assert_equal 'Triggered by a push of omansion to master (commit: 83d9205e73c25092ce7cb7ce530d2414e6d068cb)', form['cause']
    end
    svc = service(data.merge({'branches' => 'master dev'}), payload)
    svc.receive_push
  end

  def test_receive_push_branch_mismatch
    @stubs.post('/shiningpanda.org/job/pygments/build')
    svc = service(data.merge({'branches' => 'dev'}), payload)
    svc.receive_push
    begin
      @stubs.verify_stubbed_calls
    rescue RuntimeError
    else
      assert_true false
    end
  end

  def test_receive_push_branch_mismatch
    @stubs.post('/shiningpanda.org/job/pygments/build')
    svc = service(data.merge({'branches' => 'foo bar baz qux'}), payload)
    svc.receive_push
    begin
      @stubs.verify_stubbed_calls
    rescue RuntimeError
    else
      assert_true false
    end
  end

  def test_workspace_missing
    svc = service({ 'job' => 'pygments', 'token' => 'PWFm8c2T' }, payload)
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_workspace_nil
    svc = service(data.merge({'workspace' => nil}), payload)
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_workspace_blank
    svc = service(data.merge({'workspace' => ''}), payload)
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_job_missing
    svc = service({ 'workspace' => 'shiningpanda.org', 'token' => 'PWFm8c2T' }, payload)
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_job_nil
    svc = service(data.merge({'job' => nil}), payload)
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_job_blank
    svc = service(data.merge({'job' => ''}), payload)
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_token_missing
    svc = service({ 'workspace' => 'shiningpanda.org', 'job' => 'pygments' }, payload)
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_token_nil
    svc = service(data.merge({'token' => nil}), payload)
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_token_blank
    svc = service(data.merge({'token' => ''}), payload)
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_url_without_parameters
    svc = service(data, payload)
    assert_equal "https://jenkins.shiningpanda-ci.com/shiningpanda.org/job/pygments/build", svc.url
  end

  def test_url_nil_parameters
    svc = service(data.merge({'parameters' => nil}), payload)
    assert_equal "https://jenkins.shiningpanda-ci.com/shiningpanda.org/job/pygments/build", svc.url
  end

  def test_url_blank_parameters
    svc = service(data.merge({'parameters' => ''}), payload)
    assert_equal "https://jenkins.shiningpanda-ci.com/shiningpanda.org/job/pygments/build", svc.url
  end

  def test_url_with_parameters
    svc = service(data.merge({'parameters' => 'foo=bar'}), payload)
    assert_equal "https://jenkins.shiningpanda-ci.com/shiningpanda.org/job/pygments/buildWithParameters", svc.url
  end

  def test_url_strip_workspace
    svc = service(data.merge({'workspace' => ' shiningpanda.org '}), payload)
    assert_equal "https://jenkins.shiningpanda-ci.com/shiningpanda.org/job/pygments/build", svc.url
  end

  def test_url_strip_job
    svc = service(data.merge({'job' => ' pygments '}), payload)
    assert_equal "https://jenkins.shiningpanda-ci.com/shiningpanda.org/job/pygments/build", svc.url
  end

  def test_strip_token
    @stubs.post '/shiningpanda.org/job/pygments/build' do |env|
      assert_equal 'PWFm8c2T', Faraday::Utils.parse_query(env[:body])['token']
    end
    svc = service(data.merge({'token' => ' PWFm8c2T '}), payload)
    svc.receive_push
  end

  def test_multi_valued_parameter
    svc = service(data.merge({'parameters' => 'foo=bar&foo=toto'}), payload)
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def service(*args)
    super Service::ShiningPanda, *args
  end

  def payload
    {
      'after'  => '83d9205e73c25092ce7cb7ce530d2414e6d068cb',
      'ref' => 'refs/heads/master',
      'pusher' => {
        'name'   => 'omansion',
      }
    }
  end

  def data
    {
      'workspace' => 'shiningpanda.org',
      'job'       => 'pygments',
      'token'     => 'PWFm8c2T',
    }
  end
end

