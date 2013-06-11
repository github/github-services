require File.expand_path('../helper', __FILE__)

class AgileZenTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_unspecified_branch
    payload = {'answer' => 42, 'ref' => 'refs/heads/master'}
    @stubs.post '/api/v1/projects/123/changesets/github' do |env|
      body = JSON.parse(env[:body])
      assert_equal payload, body
      assert_equal 'test_api_key',     env[:request_headers]['X-Zen-ApiKey']
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      [200, {}, '']
    end

    svc = service({'api_key' => 'test_api_key', 'project_id' => '123'}, payload)
    svc.receive_push
    @stubs.verify_stubbed_calls
  end

  def test_matching_branch
    payload = {"ref" => "refs/heads/foo"}
    @stubs.post("/api/v1/projects/123/changesets/github") { |e| [200, {}, ''] }

    svc = service({'api_key' => 'test_api_key', 'project_id' => '123', 'branches' => 'foo'}, payload)
    svc.receive_push
    @stubs.verify_stubbed_calls
  end

  def test_unmatching_branch
    payload = {"ref" => "refs/heads/bar"}
    @stubs.post("/api/v1/projects/123/changesets/github") { |e| [200, {}, ''] }

    svc = service({'api_key' => 'test_api_key', 'project_id' => '123', 'branches' => 'foo'}, payload)
    svc.receive_push

    # Test that no post fired
    begin
      @stubs.verify_stubbed_calls
    rescue RuntimeError
    else
      assert_true false
    end
  end

  def test_matching_branch_of_many
    payload = {"ref" => "refs/heads/foo"}
    @stubs.post("/api/v1/projects/123/changesets/github") { |e| [200, {}, ''] }

    svc = service({'api_key' => 'test_api_key', 'project_id' => '123', 'branches' => 'baz foo'}, payload)
    svc.receive_push
    @stubs.verify_stubbed_calls
  end

  def test_unmatching_branch_of_many
    payload = {"ref" => "refs/heads/bar"}
    @stubs.post("/api/v1/projects/123/changesets/github") { |e| [200, {}, ''] }

    svc = service({'api_key' => 'test_api_key', 'project_id' => '123', 'branches' => 'baz foo'}, payload)
    svc.receive_push

    # Test that no post fired
    begin
      @stubs.verify_stubbed_calls
    rescue RuntimeError
    else
      assert_true false
    end
  end

  def test_matching_tag
    payload = {"ref" => "refs/tags/foo"}
    @stubs.post("/api/v1/projects/123/changesets/github") { |e| [200, {}, ''] }

    svc = service({'api_key' => 'test_api_key', 'project_id' => '123', 'branches' => 'foo'}, payload)
    svc.receive_push
    @stubs.verify_stubbed_calls
  end

  def service(*args)
    super Service::AgileZen, *args
  end
end
