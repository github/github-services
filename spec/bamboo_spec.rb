require File.expand_path('../../config/load', __FILE__)
require 'spec_helper'

Service::App.set :environment, :test

describe 'bamboo service' do

  EXAMPLE_BASE_URL = "http://bamboo.example.com".freeze

  def app
    Service::App
  end

  before(:each) do
    @conn = mock('nethttp')
    @conn.stub!(:use_ssl=)
    @conn.stub!(:verify_mode=)
    @http = mock('http')
    @http.stub!(:post)
    Net::HTTP.stub!(:new).and_return(@conn)
  end

  context 'when successfully posting to the bamboo server' do

    before(:each) do
      @conn.should_receive(:start).and_yield(@http).exactly(3).times
      @response = mock("response")
      @response.stub!(:body)
      @response.stub!(:code).and_return(200)
      @response.should_receive(:body).and_return("<response><auth>TOKEN123</auth></response>")
      @http.should_receive(:post).and_return(@response)
    end

    after(:each) do
      last_response.should be_ok
    end

    it "should return 200 on valid request" do
      @conn.should_receive(:use_ssl=).with(false).once
      @http.should_receive(:post).with("/api/rest/executeBuild.action", "auth=TOKEN123&buildKey=ABC").once
      post '/bamboo/', :data => data.to_json, :payload => payload.to_json
    end

    it "should use an ssl connection if necessary" do
      @conn.should_receive(:use_ssl=).with(true).once
      post '/bamboo/', :data => data.merge({'base_url' => "https://secure.bamboo.com"}).to_json, :payload => payload.to_json
    end

    it "should work properly with apps using a context path" do
      @http.should_receive(:post).with("/bamboo/api/rest/executeBuild.action", "auth=TOKEN123&buildKey=ABC").once
      post '/bamboo/', :data => data.merge({'base_url' => "http://secure.bamboo.com/bamboo/"}).to_json, :payload => payload.to_json
    end
  end


  context 'when authentication fails' do
    before(:each) do
      @conn.should_receive(:start).and_yield(@http)
      @response = mock("response")
      @response.stub!(:body)
      @response.stub!(:code).and_return(401)
      @http.should_receive(:post).and_return(@response)
    end

    it "should return 200 on valid request" do
      post '/bamboo/', :data => data.to_json, :payload => payload.to_json
      last_response.body.should =~ /Invalid credentials/
      last_response.status.should == 400
    end
  end

  context 'when invalid arguments are passed into the service' do
    it "should raise an exception if the base_url is invalid" do
      post '/bamboo/', :data => data.merge({'base_url' => ""}).to_json, :payload => payload.to_json
      last_response.status.should == 400
    end

    it "should raise an exception if the build_key is invalid" do
      post '/bamboo/', :data => data.merge({'build_key' => ''}).to_json, :payload => payload.to_json
      last_response.status.should == 400
    end
    it "should raise an exception if the username is invalid" do
      post '/bamboo/', :data => data.merge({'username' => ''}).to_json, :payload => payload.to_json
      last_response.status.should == 400
    end
    it "should raise an exception if the password is invalid" do
      post '/bamboo/', :data => data.merge({'password' => ''}).to_json, :payload => payload.to_json
      last_response.status.should == 400
    end
  end
  
  context 'when the connection to the bamboo server fails' do
    it "should return a 500 error if there is a socket getaddrinfo error" do
      @conn.should_receive(:start).and_raise(SocketError.new("getaddrinfo: Name or service not known"))
      post '/bamboo/', :data => data.to_json, :payload => payload.to_json
      last_response.status.should == 400
    end

    it "should return a 400 error if the bamboo URL is invalid" do
      @conn.should_receive(:start).and_raise(StandardError.new("Not Found (404)"))
      post '/bamboo/', :data => data.to_json, :payload => payload.to_json
      last_response.status.should == 400
    end
  end

  def data
    {
      "build_key" => "ABC",
      "base_url" => EXAMPLE_BASE_URL,
      "username" => "admin",
      "password" => 'pwd'
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



