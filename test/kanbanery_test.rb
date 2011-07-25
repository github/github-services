require File.expand_path('../helper', __FILE__)

class KanbaneryTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = '/api/v1/projects/123/git_commits'
    @stubs.post url do |env|
      assert_equal %({"a":1}), env[:body]
      assert_equal 'a1b2c3', env[:request_headers]['X-Kanbanery-ProjectGitHubToken']
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      [200, {}, '']
    end

    svc = service({'project_id' => '123', 'project_token' => 'a1b2c3'}, 'a' => 1)
    svc.receive_push
  end

  def service(*args)
    super Service::Kanbanery, *args
  end
end
