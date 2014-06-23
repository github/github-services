require File.expand_path('../helper', __FILE__)

class VisualOpsTest < Service::TestCase

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @data = {'username' => 'someuser', 'app_list' => 'abc123, madeira:master, xyz456:devel', 'consumer_token' => 'madeira-visualops'}
  end

  def test_push
    svc = service :push, @data

    @stubs.post "/v1/github" do |env|
      assert_equal 'api.visualops.io', env[:url].host
      body = JSON.parse(env[:body])
      assert_equal 'someuser',          body['config']['username']
      assert_equal 'madeira-visualops', body['config']['consumer_token']
      assert_equal ['abc123','madeira'], body['config']['app_list']
      [200, {}, '']
    end

    svc.receive_event
  end

  def test_develop
    svc = service :push, @data,
      payload.update("ref" => "refs/heads/devel")

    @stubs.post "/v1/github" do |env|
      assert_equal 'api.visualops.io', env[:url].host
      body = JSON.parse(env[:body])
      assert_equal 'someuser',          body['config']['username']
      assert_equal 'madeira-visualops', body['config']['consumer_token']
      assert_equal ['xyz456'], body['config']['app_list']
      [200, {}, '']
    end

    svc.receive_event
  end

  def test_other_branch
    svc = service :push, @data,
      payload.update("ref" => "refs/heads/no-such-branch")

    @stubs.post "/v1/github" do |env|
      raise "This should not be called"
    end

    svc.receive_event
  end

  def service(*args)
    super Service::VisualOps, *args
  end
end
