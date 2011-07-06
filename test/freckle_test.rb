require File.expand_path('../helper', __FILE__)

class FreckleTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_posts_with_2_entries
    data = call_service :push
    assert_equal 2, data['entries'].size
  end

  def test_includes_auth_token
    data = call_service :push
    assert_equal '12345', data['token']
  end

  def test_parses_minutes_from_commit_message
    data = call_service :push
    assert_equal '15', data['entries'][0]['minutes']
    assert_equal '2hrs', data['entries'][1]['minutes']
  end

  def test_strips_freckle_tags
    data = call_service :push
    assert_equal 'stub git call for Grit#heads test',
      data['entries'][0]['description']
    assert_equal 'clean up heads test',
      data['entries'][1]['description']
  end

  def test_includes_project_name
    data = call_service :push
    assert_equal 'Test Project',
      data['entries'][0]['project_name']
  end

  def test_includes_author_email_as_user
    data = call_service :push
    assert_equal 'tom@mojombo.com',
      data['entries'][0]['user']
  end

  def test_includes_commit_url
    data = call_service :push
    assert_equal 'http://github.com/mojombo/grit/commit/06f63b43050935962f84fe54473a7c5de7977325',
      data['entries'][0]['url']
  end

  def test_includes_timestamp_as_date
    data = call_service :push
    assert_equal '2007-10-10T00:11:02-07:00',
      data['entries'][0]['date']
  end

  def data
    {
      "subdomain" => "abloom",
      "token" => "12345",
      "project" => "Test Project"
    }
  end

  def service(*args)
    super Service::Freckle, *args
  end

  def call_service(event)
    res = nil
    svc  = service data, payload
    @stubs.post '/api/entries/import' do |env|
      res = JSON.parse env[:body]
    end
    svc.send "receive_#{event}"
    res
  end
end


