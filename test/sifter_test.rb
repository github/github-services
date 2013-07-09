require File.expand_path('../helper', __FILE__)

class SifterTest < Service::TestCase

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @svc   = service(data, payload)
  end

  def test_reads_token
    assert_equal token, @svc.token
  end

  def test_reads_subdomain
    assert_equal 'example', @svc.subdomain
  end

  def test_implies_host
    assert_equal "https://example.sifterapp.com/api/github", @svc.hook_url

    ENV['SIFTER_HOST'] = 'sifter.dev'
    assert_equal "http://example.sifter.dev/api/github", @svc.hook_url
    ENV.delete('SIFTER_HOST')
  end

  def test_posts_payload
    @stubs.post '/api/github' do |env|
      assert_equal 'https', env[:url].scheme
      assert_equal 'example.sifterapp.com', env[:url].host
      assert_equal token, env[:params]['token']
      assert_equal payload, JSON.parse(env[:body])
    end

    @svc.receive_push
  end

  private

  def service(*args)
    super Service::Sifter, *args
  end

  def data
    {'token' => token + ' ' * 4, 'subdomain' => 'example'}
  end

  def token
    'NTpuZXh0dXckYX4lOjE%3D'
  end

end
