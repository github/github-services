require File.expand_path('../helper', __FILE__)

class YouTrackTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @data = {'base_url' => 'http://yt.com/abc', 'committers' => 'c',
             'username' => 'u', 'password' => 'p'}
  end

  def valid_process_stubs
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
  end

  def valid_process_stubs_case_1
    valid_process_stubs

    @stubs.post "/abc/rest/issue/case-1/execute" do |env|
      assert_equal 'yt.com', env[:url].host
      assert_equal 'sc', env[:request_headers]['Cookie']
      assert_equal 'zomg omg', env[:params]['command']
      assert_equal 'mojombo', env[:params]['runAs']
      [200, {}, '']
    end
  end



  def test_push
    valid_process_stubs_case_1

    hash = payload
    hash['commits'].first['message'].sub! /Case#1/, '#case-1 zomg omg'

    svc = service(@data, hash)
    svc.receive_push

    @stubs.verify_stubbed_calls
  end

  def test_branch_match
    valid_process_stubs

    @stubs.post "/abc/rest/issue/case-2/execute" do |env|
      assert_equal 'yt.com', env[:url].host
      assert_equal 'sc', env[:request_headers]['Cookie']
      assert_equal 'Fixed', env[:params]['command']
      assert_equal 'mojombo', env[:params]['runAs']
      [200, {}, '']
    end

    hash = payload
    hash['commits'].first['message'].sub! /Case#1/, '#case-2!! zomg omg'
    hash['ref'] = 'refs/heads/master'

    svc = service(@data.merge({'branch' => 'master dev' }), hash)
    svc.receive_push

    @stubs.verify_stubbed_calls
  end

  def test_branch_mismatch
    payload = {'ref' => 'refs/heads/master'}

    svc = service({'base_url' => '', 'branch' => 'other'}, payload)

    # Missing payload settings would lead to an exception on processing. Processing
    # should never happen with mismatched branches.
    assert_nothing_raised { svc.receive_push }
  end

  def test_process_not_distinct
    valid_process_stubs_case_1

    hash = payload
    hash['commits'].each { |commit|
      commit['distinct'] = false
    }
    hash['commits'].first['message'].sub! /Case#1/, '#case-1 zomg omg'

    svc = service(@data.merge({'process_distinct' => false}), hash)

    svc.receive_push

    @stubs.verify_stubbed_calls
  end

  def test_process_distinct
    valid_process_stubs_case_1

    hash = payload
    hash['commits'].first['message'].sub! /Case#1/, '#case-1 zomg omg'

    svc = service(@data.merge({'process_distinct' => true}), hash)

    svc.receive_push

    @stubs.verify_stubbed_calls
  end

  def test_dont_process_not_distinct

    hash = payload
    hash['commits'].each { |commit|
      commit['distinct'] = false
    }
    hash['commits'].first['message'].sub! /Case#1/, '#case-1 zomg omg'

    svc = service(@data.merge({'process_distinct' => true}), hash)

    svc.receive_push

    @stubs.verify_stubbed_calls
  end

  def test_pull_request_event
    valid_process_stubs_case_1

    hash = pull_payload
    hash['action'] = 'closed'
    hash['sender'] = { 'login' => 'Tom Preston-Werner', 'email' => 'tom@mojombo.com'}
    hash['pull_request']['body'] = '#case-1 zomg omg'

    svc = service(@data, hash)

    svc.receive_pull_request

    @stubs.verify_stubbed_calls
  end

  def service(*args)
    super Service::YouTrack, *args
  end
end
