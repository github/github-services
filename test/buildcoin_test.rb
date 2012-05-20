require File.expand_path('../helper', __FILE__)

class Buildcoin < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/hooks/company_key/github/push" do |env|
      [200, {}, '']
    end
    
    svc = service(:push,{
      'company_key' => 'company_key'
    }, payload)

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_pull_request
    @stubs.post "/hooks/company_key/github/pullrequest" do |env|
      [200, {}, '']
    end

    svc = service(:pull_request,{
      'company_key' => 'company_key'
    }, payload)
  end

  def test_pull_request_review_comment
    @stubs.post "/hooks/company_key/github/pullrequestcomment" do |env|
      [200, {}, '']
    end

    svc = service(:pull_request_review_comment,{
      'company_key' => 'company_key'
    }, payload)
  end

  def test_push_missing_company_key    
    svc = service({
    }, payload)
 
    assert_raises Service::ConfigurationError do 
      svc.receive_event
    end
  end

  def service(*args)
    super Service::Buildcoin, *args
  end
end




