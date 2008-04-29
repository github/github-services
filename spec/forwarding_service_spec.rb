require File.join(File.dirname(__FILE__), *%w[spec_helper])
require 'net/http'
require 'uri'

describe "Generic GitHub service" do
  
  it "should POST the incoming payload to the specified URI" do
    payload = {'foo' => 'bar', 'baz' => 'boo'}
    URI.stubs(:parse).with('http://www.example.com/handler').returns(uri = stub)
    Net::HTTP.expects(:post_form).with(uri, payload)
    
    invoke_service(:forwarding, {'url' => 'http://www.example.com/handler'}, payload)
  end
  
end
