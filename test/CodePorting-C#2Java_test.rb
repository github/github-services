require File.expand_path('../helper', __FILE__)

class CodePortingCSharp2JavaTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @stubs.post '/csharp2java/v0/UserSignin' do |env|
      form = Faraday::Utils.parse_query(env[:body])
      assert_equal 'codeportingtest', form['LoginName']
      assert_equal 'testpassword', form['Password']
      [200, {}, %(<xml><Token>MONKEY</Token><return success="True"></return></xml>)]
    end
  end

  def test_push
    @stubs.post '/csharp2java/v0/githubpluginsupport' do |env|
      form = Faraday::Utils.parse_query(env[:body])
      assert_equal 'MONKEY', form['token']
      assert_equal 'Test_Project', form['ProjectName']
      assert_equal 'Test', form['RepoKey']
      assert_equal 'TestJava', form['TarRepoKey']
      assert_equal 'codeportingtest', form['Username']
      assert_equal 'testpassword', form['Password']
      assert_equal '0314adcacbb895bd52f3bc6f2f361ebac3ffbfb6', form['GithubAccessToken']
      [200, {}, %(<xml><return success="True"></return></xml>)]
    end

    svc = service({'project_name' => 'Test_Project',
      'repo_key' => 'Test',
      'target_repo_key' => 'TestJava',
      'codeporting_username' => 'codeportingtest',
      'codeporting_password' => 'testpassword',
      'active' => '1',
      'github_access_token' => '0314adcacbb895bd52f3bc6f2f361ebac3ffbfb6'}, payload)

    assert_equal 3, payload['commits'].size
    assert_equal "True", svc.receive_push
  end

  def service(*args)
    super Service::CodePortingCSharp2Java, *args
  end
end
