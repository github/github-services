require File.expand_path('../helper', __FILE__)

class AcunoteTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = "/source_control/github/abc"
    @stubs.post url do
      [200, {}, '']
    end

    svc = service(:push, {'token' => 'abc'}, 'payload')
    svc.receive_push
  end

  def service(*args)
    super Service::Acunote, *args
  end
end

