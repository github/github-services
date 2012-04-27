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

