require File.expand_path('../helper', __FILE__)

class ObsTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def single_token_data
    {
      # service works with all current OBS 2.5 instances
      "url" => "http://api.opensuse.org:443",
      "token" => "github/test/token/string",
      # optional
      "project" => "home:adrianSuSE",
      "package" => "4github",
    }
  end

  def multi_token_data
    {
      # service works with all current OBS 2.5 instances
      "url" => "http://api.opensuse.org:443",
      "token" => "github/test/token/one, github/test/token/two",
      # optional
      "project" => "home:adrianSuSE",
      "package" => "4github",
    }
  end

  def filter_data
    {
      "url" => "http://api.opensuse.org:443",
      "token" => "github/test/token/string",
      "project" => "home:adrianSuSE",
      "package" => "4github",
      "refs" => "refs/tags/version-*:refs/heads/production",
    }
  end

  def test_push_single_token
    apicall = "/trigger/runservice"
    @stubs.post apicall do |env|
      assert_equal 'api.opensuse.org', env[:url].host
      params = Faraday::Utils.parse_query env[:body]
      assert_equal 'Token github/test/token/string', env[:request_headers]["Authorization"]
      assert_equal '/trigger/runservice', env[:url].path
      assert_equal 'package=4github&project=home%3AadrianSuSE', env[:url].query
      [200, {}, '']
    end

    svc = service :push, single_token_data, payload
    svc.receive
  end

  def test_push_multi_token
    apicall = "/trigger/runservice"
    match = 0
    @stubs.post apicall do |env|
      assert_equal 'api.opensuse.org', env[:url].host
      params = Faraday::Utils.parse_query env[:body]
      match=match+1 if ['Token github/test/token/one', 'Token github/test/token/two'].include? env[:request_headers]["Authorization"]
      assert_equal '/trigger/runservice', env[:url].path
      assert_equal 'package=4github&project=home%3AadrianSuSE', env[:url].query
      [200, {}, '']
    end

    svc = service :push, multi_token_data, payload
    svc.receive
    # both tokens received
    assert_equal match, 2
  end

  def test_filter_passed_by_tag
    apicall = "/trigger/runservice"
    @stubs.post apicall do |env|
      assert_equal 'api.opensuse.org', env[:url].host
      params = Faraday::Utils.parse_query env[:body]
      assert_equal 'Token github/test/token/string', env[:request_headers]["Authorization"]
      assert_equal '/trigger/runservice', env[:url].path
      assert_equal 'package=4github&project=home%3AadrianSuSE', env[:url].query
      [200, {}, '']
    end

    # Modify the payload to match the filter.
    pay = payload
    pay['ref'] = 'refs/tags/version-1.1'

    svc = service :push, filter_data, pay
    assert svc.receive
    @stubs.verify_stubbed_calls
  end

  def test_filter_passed_by_branch
    apicall = "/trigger/runservice"
    @stubs.post apicall do |env|
      assert_equal 'api.opensuse.org', env[:url].host
      params = Faraday::Utils.parse_query env[:body]
      assert_equal 'Token github/test/token/string', env[:request_headers]["Authorization"]
      assert_equal '/trigger/runservice', env[:url].path
      assert_equal 'package=4github&project=home%3AadrianSuSE', env[:url].query
      [200, {}, '']
    end

    # Modify the payload to match the filter.
    pay = payload
    pay['ref'] = 'refs/heads/production'

    svc = service :push, filter_data, pay
    svc.receive
    @stubs.verify_stubbed_calls
  end

  def test_filter_rejected
    apicall = "/trigger/runservice"
    @stubs.post apicall do |env|
      flunk "Master branch should not trigger post request"
    end

    svc = service :push, filter_data, payload
    svc.receive
  end

  def service(*args)
    super Service::Obs, *args
  end
end
