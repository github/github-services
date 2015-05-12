require File.expand_path('../helper', __FILE__)

class TeamCityTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = "/abc/httpAuth/action.html"
    @stubs.get url do |env|
      assert_equal 'teamcity.com', env[:url].host
      assert_equal 'btid', env[:params]['add2Queue']
      assert_equal basic_auth(:u, :p), env[:request_headers]['authorization']
      [200, {}, '']
    end

    svc = service({
      'base_url' => 'http://teamcity.com/abc',
      'build_type_id' => 'btid',
      'username' => 'u',
      'password' => 'p',
      'check_for_changes_only' => '0'
    }, 'payload')
    svc.receive_push
  end

  def test_push_deleted_branch
    url = "/abc/httpAuth/action.html"
    @stubs.get url do |env|
      assert false, "service should not be called for deleted branches"
    end

    svc = service({
      'base_url' => 'http://teamcity.com/abc',
      'build_type_id' => 'btid'
    }, {
      'deleted' => true,
      'ref' => 'refs/heads/branch-name'
    })
    svc.receive_push
  end

  def test_push_with_branch_name
    url = "/abc/httpAuth/action.html"
    @stubs.get url do |env|
      assert_equal 'branch-name', env[:params]['branchName']
      [200, {}, '']
    end

    svc = service({
      'base_url' => 'http://teamcity.com/abc',
      'build_type_id' => 'btid'
    }, {
      'ref' => 'refs/heads/branch-name'
    })
    svc.receive_push
  end

  def test_push_with_branch_name_incl_slashes
    url = "/abc/httpAuth/action.html"
    @stubs.get url do |env|
      assert_equal 'branch/name', env[:params]['branchName']
      [200, {}, '']
    end

    svc = service({
      'base_url' => 'http://teamcity.com/abc',
      'build_type_id' => 'btid'
    }, {
      'ref' => 'refs/heads/branch/name'
    })
    svc.receive_push
  end

  def test_push_with_branch_full_ref
    url = "/abc/httpAuth/action.html"
    @stubs.get url do |env|
      assert_equal 'refs/heads/branch/name', env[:params]['branchName']
      [200, {}, '']
    end

    svc = service({
      'base_url' => 'http://teamcity.com/abc',
      'build_type_id' => 'btid',
      'full_branch_ref' => '1'
    }, {
      'ref' => 'refs/heads/branch/name'
    })
    svc.receive_push
  end

  def test_push_when_check_for_changes_is_true
    url = "/abc/httpAuth/action.html"
    @stubs.get url do |env|
      assert_equal 'teamcity.com', env[:url].host
      assert_equal 'btid', env[:params]['checkForChangesBuildType']
      [200, {}, '']
    end

    svc = service({
                      'base_url' => 'http://teamcity.com/abc',
                      'build_type_id' => 'btid',
                      'check_for_changes_only' => '1'
                  }, 'payload')
    svc.receive_push
  end



  def service(*args)
    super Service::TeamCity, *args
  end
end

