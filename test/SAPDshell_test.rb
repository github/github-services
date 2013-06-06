require File.expand_path('../helper', __FILE__)

class SAPDshellTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/api/github/a" do |env|
      assert_equal 'dshell.saphana.com', env[:url].host
      data = Faraday::Utils.parse_query(env[:body])
      assert_equal payload.to_json, data['payload']
      [200, {}, '']
    end

    svc = service({'dshell_url' => 'dshell.saphana.com:30015', 'user_id' => 'system', 'password' => 'HANA2012' }, 
                   payload)
    svc.receive_push
    
  end

  def service(*args)
    super Service::SAPDshell, *args
  end
end
