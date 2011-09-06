require File.expand_path('../helper', __FILE__)

class KickoffTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service(
      {'project_id' => '16112', 'project_token' => 'e402152277c5f9971d47f6f4840d8c89' },
      payload)
    r = svc.receive_push
    
    assert_equal '200', r.code
  end

  def service(*args)
    super Service::Kickoff, *args
  end
end

