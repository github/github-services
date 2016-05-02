require File.expand_path('../helper', __FILE__)

ART_QUERY_RESULT = 
   { 'S1234'  => {'Results' => []},
     'DE182'  => {'Results' => [{'_ref' => 'https://x.y.z/foo/defect/543221.js', 'Name' => 'Goblins', 'FormattedID' => 'DE182'}]},
     'DE171'  => {'Results' => []},
     'TA97'   => {'Results' => []},
     'TC3212' => {'Results' => []},
     'TA1294' => {'Results' => []},
     'TC1143' => {'Results' => []},
     'DE175'  => {'Results' => [{'_ref' => 'https://x.y.z/foo/defect/524175.js', 'Name' => 'Witches', 'FormattedID' => 'DE175'}]},
     'DE166'  => {'Results' => [{'_ref' => 'https://x.y.z/foo/defect/932166.js', 'Name' => 'Trollop', 'FormattedID' => 'DE166'}]}
   }


class RallyTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

   # For now, test is totally happy-path. 
   # In future should test for empty data values (server, username, password, workspace, repository)
   # raise_config_error on bad form values(server, username, password, workspace)
   # graceful failure on inability to create scmrepository, changeset, change based on Rally credentials
   # test for no payload
   # test for no payload repository, commits, ref
   # noop if no commits
   #

  def test_push

    @stubs.get '/slm/webservice/1.30/Subscription.js?fetch=Name,Workspaces,Workspace&pretty=true' do |env|
        assert_equal 'crubble.rallydev.com', env[:url].host
        subs = { 'Name'     => "Omicron Bacan Fluffies",
                 'Errors'   => [],
                 'Warnings' => [],
                 'Workspaces' => [ {"Name" => "Chloroformer",
                                    "_ref" => "https://crubble.rallydev.com/slm/webservice/1.30/workspace/662372755.js",
                                    "_refObjectName" => "Chlorformer",
                                   }
                                 ]
               }
        [200, {}, JSON.generate({"Subscription" => subs})]
    end

    @stubs.get '/slm/webservice/1.30/scmrepository.js' do |env|
        repo = {"Errors"   => [], 
                "Warnings" => [], 
                "TotalResultCount" => 1, "StartIndex" => 1, "PageSize" => 20, 
                "Results" => [
                              { 
                                "Name"  => "Reservoir Dogs", 
                                "_type" => "SCMRepository",
                                "_ref"  => "https://trial.rallydev.com/slm/webservice/1.30/scmrepository/11432875342.js"  
                              } 
                             ]
               } 
        [200, {}, JSON.generate({"QueryResult" => repo})]
    end

    @stubs.get '/slm/webservice/1.30/hierarchicalrequirement.js' do |env|
        result = artifact_query_response(env[:url])
        [200, {}, result]
    end

    @stubs.get '/slm/webservice/1.30/defect.js' do |env|
        result = artifact_query_response(env[:url])
        [200, {}, result]
    end

    @stubs.get '/slm/webservice/1.30/task.js' do |env|
        result = artifact_query_response(env[:url])
        [200, {}, result]
    end

    @stubs.get '/slm/webservice/1.30/testcase.js' do |env|
        result = artifact_query_response(env[:url])
        [200, {}, result]
    end

    @stubs.get '/slm/webservice/1.30/user.js' do |env|
        assert_equal 'crubble.rallydev.com', env[:url].host
        assert_equal 'https',                env[:url].scheme
        user_item = { "Name"     => "Romeo",
                      "UserName" => "romeo_must_die",
                      "_ref"     => "https://crubble.rallydev.com/slm/webservice/1.30/user/919235435.js"
                    }
        user_result = {"Errors" => [], "Warnings" => [], "TotalResultCount" => 1, 'Results' => [user_item]}
        [200, {}, JSON.generate({'QueryResult' => user_result})]
    end

    @stubs.post '/slm/webservice/1.30/scmrepository/create.js' do |env|
      repo_result = {'Object' => {"_ref" => 'http://x.y.z/foo/scmrepository/4433556.js'}}
      [200, {}, JSON.generate({'CreateResult' => repo_result})]
    end

    @stubs.post '/slm/webservice/1.30/Changeset/create.js' do |env|
      chgset_result = {"Object" => {"_ref" => 'http://x.y.z/foo/changeset/639214.js'}}
      [200, {}, JSON.generate({'CreateResult' => chgset_result})]
    end

    @stubs.post '/slm/webservice/1.30/Change/create.js' do |env|
      chg_result = {"Object" => {"_ref" => 'http://x.y.z/foo/change/7366456.js'}}
      [200, {}, JSON.generate({'CreateResult' => chg_result})]
    end


    data = { 'server'     => 'crubble', 
             'username'   => 'romeo_must_die', 
             'password'   => 'Plantrachette', 
             'workspace'  => 'Chloroformer',
             'repository' => 'Reservoir Dogs'
           }
    payload = rally_test_payload()

    svc = service(data, payload)
    svc.receive_push
  end

  def artifact_query_response(req)
    resp = {"Errors" => [], "Warnings" => [], "TotalResultCount" => 0}
    if URI.decode(req.to_s.split('?')[1]) =~ /query=\(FormattedID = ([A-Z]{1,2}\d+)\)/
      art_id = $1
      resp = resp.merge(ART_QUERY_RESULT[art_id])
      resp["TotalResultCount"] = ART_QUERY_RESULT[art_id]["Results"].length
    end
    return JSON.generate({"QueryResult" => resp})
  end

  def rally_test_payload()
    rally_payload = 
        { "after"   => "a47fd41f3aa4610ea527dcc1669dfdb9c15c5425",
          "ref"     => "refs/heads/master",
          "before"  => "4c8124ffcf4039d292442eeccabdeca5af5c5017",
          "compare" => "https://github.com/kipster-t/powalla/compare/4c8124ffcf4039d292442eeccabdeca5af5c5017...a47fd41f3aa4610ea527dcc1669dfdb9c15c5425",
          "forced"  => false,
          "created" => false,
          "deleted" => false,

          "repository" => {
            "name"  => "powalla",
            "url"   => "https://github.com/kipster-t/powalla",
            "owner" => { "name" => "kipster-t", "email" => "klehman@rallydev.com" }
          },

          "pusher" => {
            "name" => "YetiShaggy"
          },

          "commits" => [
            {
              "id"        => "06f63b43050935962f84fe54473a7c5de7977325",
              "timestamp" => "2012-01-10T00:11:02-07:00",
              "author"    => { "name" => "Yeti", "email" => "yeti@rallydev.com" },
              "message"   => "Altered S1234 and DE182, Fixed DE171 and Completed TA97. Improved layout and code cohesion",
              "added"     => ["bus/pricing-model.txt"],
              "modified"  => ["lib/grit/grit.rb", "test/helper.rb", "test/test_grit.rb"],
              "removed"   => [],
              "url"       => "https://github.com/kipster-t/powalla/commit/06f63b43050935962f84fe54473a7c5de7977325",
              "distinct"  => true
            },
            {
              "id"        => "5057e76a11abd02e83b7d3d3171c4b68d9c88480",
              "timestamp" => "2012-01-10T00:18:20-07:00",
              "author"    => { "name" => "Yeti", "email" => "yeti@rallydev.com" },
              "message"   => "clean up heads test, TC3212 cleared, Completed TA1294 and your mama is really mad at your 1954 Mustache.js attitude foda MUS1965 roadasster",
              "added"     => [],
              "modified"  => ["test/test_grit.rb"],
              "removed"   => ["test/test_grotty.rb", "test/test_joobbar.rb"],
              "url"       => "https://github.com/kipster-t/powalla/commit/5057e76a11abd02e83b7d3d3171c4b68d9c88480",
              "distinct"  => true
            },
            {
              "id"        => "a47fd41f3aa4610ea527dcc1669dfdb9c15c5425",
              "timestamp" => "2012-01-10T00:50:39-07:00",
              "author"    => { "name" => "Yeti", "email" => "yeti@rallydev.com" },
              "message"   => "TC1143 Passed and DE175 Fixed but DE166 left behind in state of Disrepair",
              "added"     => ["docs/messieurs.pdf"],
              "modified"  => ["README", "lib/grit/commiteur.rb"],
              "removed"   => ["too_gritty.rb"],
              "url"       => "https://github.com/kipster-t/powalla/commit/a47fd41f3aa4610ea527dcc1669dfdb9c15c5425",
              "distinct"  => true
            }
          ]
        }
    return rally_payload
  end

  def service(*args)
    super Service::Rally, *args
  end

end

