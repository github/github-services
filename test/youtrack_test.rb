require File.expand_path('../helper', __FILE__)

class YouTrackTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/abc/rest/user/login" do |env|
      assert_equal 'yt.com', env[:url].host
      assert_equal 'u', env[:params]["login"]
      assert_equal 'p', env[:params]["password"]
      [200, {'Set-Cookie' => 'sc'}, '']
    end

    @stubs.get "/abc/rest/admin/user" do |env|
      assert_equal 'yt.com', env[:url].host
      assert_equal 'sc', env[:request_headers]['Cookie']
      assert_equal 'tom@mojombo.com', env[:params]['q']
      assert_equal 'c', env[:params]['group']
      assert_equal '0', env[:params]['start']
      [200, {}, %(<r><u login="mojombo" /></r>)]
    end

    @stubs.get "/abc/rest/admin/user/mojombo" do |env|
      assert_equal 'yt.com', env[:url].host
      assert_equal 'sc', env[:request_headers]['Cookie']
      [200, {}, %(<u email="tom@mojombo.com" />)]
    end

    @stubs.post "/abc/rest/issue/case-1/execute" do |env|
      assert_equal 'yt.com', env[:url].host
      assert_equal 'sc', env[:request_headers]['Cookie']
      assert_equal 'zomg omg', env[:params]['command']
      assert_equal 'mojombo', env[:params]['runAs']
    end

    hash = payload
    hash['commits'].first['message'].sub! /Case#1/, '#case-1 zomg omg'

    svc = service({'base_url' => 'http://yt.com/abc', 'committers' => 'c',
                   'username' => 'u', 'password' => 'p'}, hash)
    svc.receive_push
  end

  def service(*args)
    super Service::YouTrack, *args
  end
end

