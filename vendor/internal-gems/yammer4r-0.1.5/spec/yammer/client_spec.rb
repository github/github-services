require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'ostruct'

describe Yammer::Client do
  
  context "creating" do
  
    before(:each) do
      mock_consumer = mock(OAuth::Consumer)
      OAuth::Consumer.stub!("new").and_return(mock_consumer)
      @mock_http = mock("http")
      mock_consumer.stub!("http").and_return(@mock_http)
    end
  
    it "can be configured to be verbose" do
      @mock_http.should_receive("set_debug_output").with($stderr)
      Yammer::Client.new(:consumer => {}, :access => {}, :verbose => true)
    end

    it "should not be configured to be verbose unless asked to be" do
      @mock_http.should_not_receive("set_debug_output")
      Yammer::Client.new(:consumer => {}, :access => {})
    end

    it "should not be configured to be verbose if asked not to be" do
      @mock_http.should_not_receive("set_debug_output")
      Yammer::Client.new(:consumer => {}, :access => {}, :verbose => false)
    end

  end  
  
  context "users" do
    
    before(:each) do
      @mock_access_token = mock(OAuth::AccessToken)
      @response = OpenStruct.new(:code => 200, :body => '{}')
      OAuth::AccessToken.stub!("new").and_return(@mock_access_token)
      @client = Yammer::Client.new(:consumer => {}, :access => {})
    end
    
    it "should request the first page by default" do
      @mock_access_token.should_receive("get").with("/api/v1/users.json").and_return(@response)
      @client.users
    end
    
    it "can request a specified page" do
      @mock_access_token.should_receive("get").with("/api/v1/users.json?page=2").and_return(@response)
      @client.users(:page => 2)
    end
    
  end  
  
end