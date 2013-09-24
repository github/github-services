require File.expand_path('../helper', __FILE__)

class TenderTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new

    @options = {
      'domain' => 'some.tenderapp.com',
      'token'  => 'Aewi5ui1'
    }
  end

  def test_issues
    @stubs.post "/tickets/github/Aewi5ui1" do |env|
      body = JSON.parse(env[:body])

      assert_equal 'https', env[:url].scheme
      assert !env[:ssl][:verify]
      assert_equal 'some.tenderapp.com', env[:url].host
      assert_equal 'application/json', env[:request_headers]['Content-Type']

      assert_equal body["issue"]["state"], "open"
      assert_equal body["issue"]["number"], 5
      assert_equal body["repository"]["name"], "grit"
      assert_equal body["repository"]["owner"]["login"], "mojombo"

      [200, {}, '']
    end

    service(:issues, @options, issues_payload).receive_issues
  end

  def service(*args)
    super Service::Tender, *args
  end
end
