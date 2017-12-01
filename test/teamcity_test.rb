require File.expand_path('../helper', __FILE__)

class TeamCityTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = "/abc/httpAuth/app/rest/buildQueue"
    @stubs.post url do |env|
      assert_equal 'teamcity.com', env[:url].host
      assert_equal '<build branchName=""><buildType id="btid"/></build>', env[:body]
      assert_equal basic_auth(:u, :p), env[:request_headers]['authorization']
      [200, {}, '']
    end

    url2 = "abc/httpAuth/app/rest/vcs-root-instances/checkingForChangesQueue?locator=buildType:btid"
    @stubs.post url2 do |env|
      assert_equal 'teamcity.com', env[:url].host
      assert_equal nil, env[:body]
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
    @stubs.post url do |env|
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
    url = "/abc/httpAuth/app/rest/buildQueue"
    @stubs.post url do |env|
      assert_equal '<build branchName="branch-name"><buildType id="btid"/></build>', env[:body]
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
    url = "/abc/httpAuth/app/rest/buildQueue"
    @stubs.post url do |env|
      assert_equal '<build branchName="branch/name"><buildType id="btid"/></build>', env[:body]
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
    url = "/abc/httpAuth/app/rest/buildQueue"
    @stubs.post url do |env|
      assert_equal '<build branchName="refs/heads/branch/name"><buildType id="btid"/></build>', env[:body]
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
    url = "abc/httpAuth/app/rest/vcs-root-instances/checkingForChangesQueue?locator=buildType:btid"
    @stubs.post url do |env|
      assert_equal 'teamcity.com', env[:url].host
      assert_equal "", env[:body]
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

