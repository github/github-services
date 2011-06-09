require File.expand_path('../helper', __FILE__)

class UnfuddleTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.get '/api/v1/people.json' do |env|
      assert_equal 's.unfuddle.com', env[:url].host
      assert_equal basic_auth(:u, :p), env[:request_headers]['authorization']
      [200, {}, [{:email => 'tom@mojombo.com', :account_id => 1}].to_json]
    end

    @stubs.post '/api/v1/repositories/2/changesets.json' do |env|
      assert_equal 's.unfuddle.com', env[:url].host
      assert_equal basic_auth(:u, :p), env[:request_headers]['authorization']
      [200, {'Location' => '/abc'}, '']
    end

    @stubs.put '/abc' do
      [200, {}, '']
    end

    svc = service({
      'repo_id' => '2.0', 'subdomain' => 's',
      'username' => 'u', 'password' => 'p'}, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Unfuddle, *args
  end
end

