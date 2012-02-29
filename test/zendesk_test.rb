require File.expand_path('../helper', __FILE__)

class ZendeskTest < Service::TestCase
   def setup
      @stubs = Faraday::Adapter::Test::Stubs.new
    end

    def test_subdomain
      post

      svc = service :event,
        {'username' => 'user', 'password' => 'pass', 'subdomain' => 'igor'}, :message => 'My name is zd#12345 what do you say?'
      svc.receive_event
    end

    def test_domain
      post

      svc = service :event,
        {'username' => 'user', 'password' => 'pass', 'subdomain' => 'igor.zendesk.com'}, :message => 'My name is zd#12345 what do you say?'
      svc.receive_event
    end

    def test_unmatched_ticket
      post

      svc = service :event,
        {'username' => 'user', 'password' => 'pass', 'subdomain' => 'igor'}, :message => 'My name is 12345 what do you say?'
      svc.receive_event  

      begin
        @stubs.verify_stubbed_calls
      rescue RuntimeError
      else
        assert_true false
      end  
    end
    
    def post
      @stubs.post "/api/v2/integrations/github" do |env|
        assert_equal 'application/json', env[:request_headers]['Content-Type']       
        assert_equal 'igor.zendesk.com', env[:url].host
        assert_equal '12345', env[:body][:ticket_id]
        assert_equal JSON.generate({:message => 'My name is zd#12345 what do you say?'}), env[:body][:payload]
        [201, {}, '']
      end
    end


    def service(*args)
      super Service::Zendesk, *args
    end
end


