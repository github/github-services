require File.expand_path('../helper', __FILE__)

class BlimpTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new

    @options = {
      'project_url' => 'https://app.getblimp.com/acme-inc/example-project/',
      'username' => 'example',
      'api_key' => 'secret'
    }
  end

  def test_issues
    @stubs.post '/api/v2/github_service/' do |env|
      expected = {
        'company_url' => 'acme-inc',
        'project_url' => 'example-project',
        'goal_title' => 'Github Issues - mojombo/grit',
        'event' => 'issues',
        'payload' => {
          'repository' => {
            'owner' => {
              'login' => 'mojombo'
            },
            'name' => 'grit',
            'url' => 'http://github.com/mojombo/grit'
          },
          'issue' => {
            'title' => 'booya',
            'state' => 'open',
            'user' => {
              'login' => 'mojombo'
            },
            'body' => 'boom town',
            'number' => 5,
            'html_url' => 'html_url'
          },
          'sender' => {
            'login' => 'defunkt'
          },
          'action' => 'opened'
        }
      }
      assert_equal expected, JSON.parse(env[:body])

      [200, {}, '']
    end

    service(:issues, @options, issues_payload).receive_event
  end

  def service(*args)
    super Service::Blimp, *args
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