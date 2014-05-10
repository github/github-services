require File.expand_path("../helper", __FILE__)

# stub
require "maxcdn"
module MaxCDN
  class Client
    def initialize *args
      @purge_calls = 0
      @fake_error  = false
    end

    def purge id
      raise ::MaxCDN::APIException.new("test error") if @fake_error

      @purge_calls += 1
      return { "code" => "200" }
    end

    def fake_error
      @fake_error = true
    end
  end
end

class MaxCDNTest < Service::TestCase
  def setup
    @arguments ||= {
      "alias"       => "foobar_alias",
      "key"         => "foobar_key",
      "secret"      => "foobar_secret",
      "zone_id"     => 123456,
      "static_only" => false
    }

    @svc = service(@arguments, dynamic_payload)
  end

  def test_maxcdn
    assert @svc.maxcdn
  end

  def test_extensions
    assert_includes @svc.extensions, :js
  end

  def test_has_static?
    refute @svc.has_static?

    svc = service(@arguments, static_payload)
    assert svc.has_static?
  end

  def test_receive_push
    assert @svc.receive_push
    assert_equal 1, @svc.maxcdn.instance_variable_get(:@purge_calls)

    @svc.maxcdn.fake_error
    error = assert_raises ::Service::ConfigurationError do
      @svc.receive_push
    end

    assert_match /test error/, error.message

    arguments = @arguments.clone
    arguments["static_only"] = true
    svc = service(arguments, payload)

    refute svc.receive_push

    arguments = @arguments.clone
    arguments["static_only"] = true
    svc = service(arguments, static_payload)

    assert svc.receive_push
  end

  def dynamic_payload
    unless defined? @dynamic_payload
      # Default payload is all .rb files and thus, a
      # non-static payload. However, to be sure (should
      # something change in the future) I'll ensure it.
      @dynamic_payload = payload.clone
      @dynamic_payload["commits"].each_index do |commit|
        @dynamic_payload["commits"][commit]["modified"].each_index do |file|
          @dynamic_payload["commits"][commit]["modified"][file].gsub!(/\.[a-z0-9]+$/, ".rb")
        end
      end
    end
    @dynamic_payload
  end

  def static_payload
    unless defined? @static_payload
      # Creating a static payload, by replacing a single
      # file in the payload with a static file extension.
      @static_payload  = payload.clone
      @static_payload["commits"]
          .first["modified"]
          .last
          .gsub!(/\.[a-z0-9]+$/, ".js")
    end
    @static_payload
  end

  def service(*args)
    super Service::MaxCDN, *args
  end
end
