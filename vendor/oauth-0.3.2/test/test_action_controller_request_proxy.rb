require File.dirname(__FILE__) + '/test_helper.rb'
require 'oauth/request_proxy/action_controller_request.rb'
require 'action_controller'
require 'action_controller/test_process'

class ActionControllerRequestProxyTest < Test::Unit::TestCase

  def request_proxy(parameters={})
    request = ActionController::TestRequest.new({}, parameters)
    request.env['CONTENT_TYPE'] = 'application/x-www-form-urlencoded'
    yield request if block_given?
    OAuth::RequestProxy.proxy(request)
  end
 
  def test_parameter_keys_should_preserve_brackets_from_hash
    assert_equal(
      [["message[body]", "This is a test"]],
      request_proxy({ :message => { :body => 'This is a test' }}).parameters_for_signature
    )
  end
  
  def test_parameter_values_with_amps_should_not_break_parameter_parsing
    assert_equal(
      [['message[body]', 'http://foo.com/?a=b&c=d']],
      request_proxy({ :message => { :body => 'http://foo.com/?a=b&c=d'}}).parameters_for_signature
    )
  end

  def test_parameter_keys_should_preserve_brackets_from_array
    assert_equal(
      [["foo[]", "123"], ["foo[]", "456"]],
      request_proxy({ :foo => [123, 456] }).parameters_for_signature.sort
    )
  end
  
  def test_query_string_parameter_values_should_be_cgi_unescaped
    request = request_proxy do |r|
      r.env['QUERY_STRING'] = 'url=http%3A%2F%2Ffoo.com%2F%3Fa%3Db%26c%3Dd'
    end
    assert_equal(
      [['url', 'http://foo.com/?a=b&c=d']],
      request.parameters_for_signature.sort
    )
  end
end
