require File.expand_path('../helper', __FILE__)

class CodePortingCSharp2JavaTest < Service::TestCase
  def test_push
    svc = service({'project_name' => 'Test_Project', 
	     'repo_key' => 'Test', 
		 'target_repo_key' => 'TestJava', 
		 'username' => 'codeportingtest', 
		 'password' => 'testpassword', 
		 'active' => '1', 
		 'userid' => 'CodePorting'}, payload)

	assert_equal 1, @payload['commits'].size
	response = svc.receive_push
	if (response == "True")
	  raise "Service hook performed good"
	else
	  raise "Service failure! #{response}"
	end
  end
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
	string   :project_name, :repo_key, :target_repo_key, :username, :password
  boolean  :active
  string   :userid
    @data = {
      'project_name' => 'Test_Project',
      'repo_key' => 'Test',
      'target_repo_key' => 'TestJava',
      'username' => 'codeportingtest',
      'password' => 'testpassword',
	  'active' => '1',
	  'userid' => 'CodePorting'
    }
    @payload = {
      "after"   => "a47fd41f3aa4610ea527dcc1669dfdb9c15c5425",
      "ref"     => "refs/heads/master",
      "before"  => "4c8124ffcf4039d292442eeccabdeca5af5c5017",
      "compare" => "http://github.com/mojombo/grit/compare/4c8124ffcf4039d292442eeccabdeca5af5c5017...a47fd41f3aa4610ea527dcc1669dfdb9c15c5425",
      "forced"  => false,
      "created" => false,
      "deleted" => false,

      "repository" => {
        "name"  => "Test",
        "url"   => "https://github.com/CodePorting/Test",
        "owner" => { "name" => "CodePorting", "email" => "mohsan.raza@codeporting.com" }
      },

      "pusher" => {
        "name" => "iqbal"
      },

      "commits" => [
        {
          "distinct"  => true,
          "removed"   => [],
          "message"   => "[#WEB-249 status:31 resolution:1] stub git call for Grit#heads test",
          "added"     => [],
          "timestamp" => "2007-10-10T00:11:02-07:00",
          "modified"  => ["lib/grit/grit.rb", "test/helper.rb", "test/test_grit.rb"],
          "url"       => "http://github.com/mojombo/grit/commit/06f63b43050935962f84fe54473a7c5de7977325",
          "author"    => { "name" => "Tom Preston-Werner", "email" => "tom@mojombo.com" },
          "id"        => "06f63b43050935962f84fe54473a7c5de7977325"
        }
      ]
    }
  end

  def test_push_master_only_on_non_master
    svc = service({'project_name' => 'Test_Project', 
	     'repo_key' => 'Test', 
		 'target_repo_key' => 'TestJava', 
		 'username' => 'codeportingtest', 
		 'password' => 'testpassword', 
		 'active' => '1', 
		 'userid' => 'CodePorting'}, payload)

	assert_equal 1, @payload['commits'].size
	response = svc.receive_push
	if (response == "True")
	  raise "Service hook performed good"
	else
	  raise "Service failure! #{response}"
	end
  end

  def test_push_master_only_on_master
    svc = service({'project_name' => 'Test_Project', 
	     'repo_key' => 'Test', 
		 'target_repo_key' => 'TestJava', 
		 'username' => 'codeportingtest', 
		 'password' => 'testpassword', 
		 'active' => '1', 
		 'userid' => 'CodePorting'}, payload)

	assert_equal 1, @payload['commits'].size
	response = svc.receive_push
	if (response == "True")
	  raise "Service hook performed good"
	else
	  raise "Service failure! #{response}"
	end
  end

  def service(*args)
    super Service::CodePortingCSharp2Java, *args
  end
end

