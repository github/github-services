require File.expand_path('../helper', __FILE__)

class BasecampTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new

    @options = {
      'project_url'   => 'https://basecamp.com/123/projects/456',
      'email_address' => 'a@b.com',
      'password'      => 'secret' }
  end

  def test_push
    @stubs.post '/123/api/v1/projects/456/events.json' do |env|
      assert_equal 'https', env[:url].scheme
      assert_equal 'basecamp.com', env[:url].host

      assert_equal 'Basic YUBiLmNvbTpzZWNyZXQ=', env[:request_headers]['Authorization']

      assert_match 'GitHub', env[:request_headers]['User-Agent']
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal 'application/json', env[:request_headers]['Accept']

      expected = {
        'service' => Service::Basecamp::SERVICE_NAME,
        'logo_url' => Service::Basecamp::LOGO_URL,
        'creator_email_address' => 'tom@mojombo.com',
        'description' => 'committed',
        'title' => 'pushed 3 new commits to master',
        'url' => 'http://github.com/mojombo/grit/compare/4c8124f...a47fd41' }
      assert_equal expected, JSON.parse(env[:body])

      [200, {}, '']
    end

    service(@options, payload).receive_push
  end

  def test_pull
    @stubs.post '/123/api/v1/projects/456/events.json' do |env|
      expected = {
        'service' => Service::Basecamp::SERVICE_NAME,
        'logo_url' => Service::Basecamp::LOGO_URL,
        'creator_email_address' => nil,
        'description' => 'opened a pull request',
        'title' => 'booya (master..feature)',
        'url' => 'html_url' }
      assert_equal expected, JSON.parse(env[:body])

      [200, {}, '']
    end

    service(:pull_request, @options, pull_payload).receive_pull_request
  end

  def test_issues
    @stubs.post '/123/api/v1/projects/456/events.json' do |env|
      expected = {
        'service' => Service::Basecamp::SERVICE_NAME,
        'logo_url' => Service::Basecamp::LOGO_URL,
        'creator_email_address' => nil,
        'description' => 'opened an issue',
        'title' => 'booya',
        'url' => 'html_url' }
      assert_equal expected, JSON.parse(env[:body])

      [200, {}, '']
    end

    service(:issues, @options, issues_payload).receive_issues
  end

  def service(*args)
    super Service::Basecamp, *args
  end

  # No html_url in default payload
  def pull_payload
    super.tap do |payload|
      payload['pull_request']['html_url'] = 'html_url'
    end
  end

  # No html_url in default payload
  def issues_payload
    super.tap do |payload|
      payload['issue']['html_url'] = 'html_url'
    end
  end
end
