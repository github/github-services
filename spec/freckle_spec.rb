require 'sinatra'
require 'sinatra/test/rspec'
require 'github-services'

describe 'service freckle' do

  before(:each) do
    @req = mock('req')
    @req.stub!(:set_content_type)
    @req.class_eval do
      attr_accessor :body
    end
    Net::HTTP::Post.stub!(:new).and_return(@req)
    Net::HTTP.stub!(:new).and_return(mock('nethttp', :start => nil))
  end

  it 'should be ok' do
    do_request
    @response.should be_ok
  end

  it 'should post with 2 entries' do
    do_request
    @data['entries'].size.should == 2
  end

  it 'should include auth token' do
    do_request
    @data['token'].should == '12345'
  end

  it 'should parse the amount of minutes from the commit message' do
    do_request
    @data['entries'][0]['minutes'].should == '15'
    @data['entries'][1]['minutes'].should == '2hrs'
  end

  it 'should strip freckle tags from description' do
    do_request
    @data['entries'][0]['description'].should == 'stub git call for Grit#heads test'
    @data['entries'][1]['description'].should == 'clean up heads test'
  end

  it 'should include project name' do
    do_request
    @data['entries'][0]['project_name'].should == 'Test Project'
  end

  it 'should include author email as user' do
    do_request
    @data['entries'][0]['user'].should == 'tom@mojombo.com'
  end

  it 'should include commit url' do
    do_request
    @data['entries'][0]['url'].should == 'http://github.com/mojombo/grit/commit/06f63b43050935962f84fe54473a7c5de7977325'
  end

  it 'should include timestamp as date' do
    do_request
    @data['entries'][0]['date'].should == '2007-10-10T00:11:02-07:00'
  end

  def do_request
    post '/freckle/', :data => data.to_json, :payload => payload.to_json
    @data = JSON.parse(@req.body)
  end

  def data
    {
      "subdomain" => "abloom",
      "token" => "12345",
      "project" => "Test Project"
    }
  end

  def payload
    {
      "after"  => "a47fd41f3aa4610ea527dcc1669dfdb9c15c5425",
      "ref"    => "refs/heads/master",
      "before" => "4c8124ffcf4039d292442eeccabdeca5af5c5017",

      "repository" => {
        "name"  => "grit",
        "url"   => "http://github.com/mojombo/grit",
        "owner" => { "name" => "mojombo", "email" => "tom@mojombo.com" }
      },

      "commits" => [
        {
          "removed"   => [],
          "message"   => "stub git call for Grit#heads test f:15",
          "added"     => [],
          "timestamp" => "2007-10-10T00:11:02-07:00",
          "modified"  => ["lib/grit/grit.rb", "test/helper.rb", "test/test_grit.rb"],
          "url"       => "http://github.com/mojombo/grit/commit/06f63b43050935962f84fe54473a7c5de7977325",
          "author"    => { "name" => "Tom Preston-Werner", "email" => "tom@mojombo.com" },
          "id"        => "06f63b43050935962f84fe54473a7c5de7977325"
        },
        {
          "removed"   => [],
          "message"   => "clean up heads test f:2hrs",
          "added"     => [],
          "timestamp" => "2007-10-10T00:18:20-07:00",
          "modified"  => ["test/test_grit.rb"],
          "url"       => "http://github.com/mojombo/grit/commit/5057e76a11abd02e83b7d3d3171c4b68d9c88480",
          "author"    => { "name" => "Tom Preston-Werner", "email" => "tom@mojombo.com" },
          "id"        => "5057e76a11abd02e83b7d3d3171c4b68d9c88480"
        },
        {
          "removed"   => [],
          "message"   => "add more comments throughout",
          "added"     => [],
          "timestamp" => "2007-10-10T00:50:39-07:00",
          "modified"  => ["lib/grit.rb", "lib/grit/commit.rb", "lib/grit/grit.rb"],
          "url"       => "http://github.com/mojombo/grit/commit/a47fd41f3aa4610ea527dcc1669dfdb9c15c5425",
          "author"    => { "name" => "Tom Preston-Werner", "email" => "tom@mojombo.com" },
          "id"        => "a47fd41f3aa4610ea527dcc1669dfdb9c15c5425"
        }
      ]
    }
  end
end
