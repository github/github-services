require File.expand_path('../helper', __FILE__)

class AppHarborTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
  end

  def service(*args)
    super Service::AppHarbor, *args
  end
end
