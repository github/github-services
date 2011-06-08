require File.expand_path('../helper', __FILE__)

class FogBugzTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = "/fb?"
    url << "ixBug=1&"
    url << "ixRepository=r&"
    url << "sFile=%2Flib%2Fgrit%2Fgrit.rb&"
    url << "sNew=06f63b43050935962f84fe54473a7c5de7977325&"
    url << "sPrev=4c8124ffcf4039d292442eeccabdeca5af5c5017"

    @stubs.get url do |env|
      [200, {}, '']
    end

    svc = service :push,
      {'cvssubmit_url' => '/fb', 'fb_repoid' => 'r'},
      modified_payload
    svc.receive_push
  end

  def test_push_for_fogbugz_6
    url = "/fb?"
    url << "ixBug=1&"
    url << "sFile=%2Flib%2Fgrit%2Fgrit.rb&"
    url << "sNew=06f63b43050935962f84fe54473a7c5de7977325&"
    url << "sPrev=4c8124ffcf4039d292442eeccabdeca5af5c5017&"
    url << "sRepo=grit"

    @stubs.get url do |env|
      [200, {}, '']
    end

    svc = service :push,
      {'cvssubmit_url' => '/fb', 'fb_repoid' => 'r', 'fb_version' => '6'},
      modified_payload
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


