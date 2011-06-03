require File.expand_path('../helper', __FILE__)

class AcunoteTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @service = AcunoteService.new(:push, 'data', 'payload')
    @service.faraday = Faraday.new { |b| b.adapter(:test, @stubs) }
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
    super AcunoteService, *args
  end
end

