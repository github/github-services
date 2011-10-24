require File.expand_path('../helper', __FILE__)

class FogBugzTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = "/fb?"
    url << "ixBug=1&"
    url << "ixRepository=r&"
    url << "sFile=master%2Flib%2Fgrit%2Fgrit.rb&"
    url << "sNew=06f63b43050935962f84fe54473a7c5de7977325&"
    url << "sPrev=4c8124ffcf4039d292442eeccabdeca5af5c5017"

    @stubs.get url do |env|
      [200, {}, '']
    end

    svc = service(
      {'cvssubmit_url' => '/fb', 'fb_repoid' => 'r'},
      modified_payload)
    svc.receive_push
  end

  def test_push_for_fogbugz_6
    @stubs.get '/fb' do |env|
      assert_equal '1', env[:params]['ixBug']
      assert_equal 'master/lib/grit/grit.rb', env[:params]['sFile']
      assert_equal '06f63b43050935962f84fe54473a7c5de7977325', env[:params]['sNew']
      assert_equal '4c8124ffcf4039d292442eeccabdeca5af5c5017', env[:params]['sPrev']
      assert_equal 'grit', env[:params]['sRepo']
      [200, {}, '']
    end

    svc = service(
      {'cvssubmit_url' => '/fb', 'fb_repoid' => 'r', 'fb_version' => '6'},
      modified_payload)
    svc.receive_push
  end

  def service(*args)
    super Service::FogBugz, *args
  end

  def modified_payload
    pay = payload
    pay['commits'].pop
    pay['commits'].pop
    pay['commits'][0]['modified'].pop
    pay['commits'][0]['modified'].pop
    pay
  end
end


