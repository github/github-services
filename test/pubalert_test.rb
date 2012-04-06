require File.expand_path('../helper', __FILE__)

class PubAlertTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_public
    @stubs.post "http://127.0.0.1:8000/make_repo_private" do |env|
      env.inspect
      [200, {}, '']
    end

    svc = service :public,
      {'remote_url' => 'http://127.0.0.1:8000/make_repo_private',
       'auth_token' => 'sometoken',
       'repo_name'  => 'testrepo'}
    svc.receive_public
  end

  def service(*args)
    super Service::PubAlert, *args
  end
end
