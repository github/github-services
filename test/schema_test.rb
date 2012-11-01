require File.expand_path('../helper', __FILE__)

class DefaultSchemaTest < Service::TestCase
  class SchemaService < Service
  end

  def setup
    @svc = SchemaService
  end

  def test_title
    assert_equal 'SchemaService', @svc.title
  end

  def test_hook_name
    assert_equal 'schemaservice', @svc.hook_name
  end

  def test_default_events
    assert_equal [:push], @svc.default_events
  end

  def test_supported_events
    assert_equal [], @svc.supported_events
  end

  def test_schema
    assert_equal [], @svc.schema
  end

  def test_white_listed_attributes
    assert_equal [], @svc.white_listed
  end
end

class DefaultSchemaWithEventsTest < DefaultSchemaTest
  class SchemaService < Service
    def receive_push
    end

    def receive_issues
    end
  end

  def setup
    @svc = SchemaService
  end

  def test_supported_events
    assert_equal %w(issues push), @svc.supported_events.sort
  end
end

class DefaultSchemaWithAllEventsTest < DefaultSchemaTest
  class SchemaService < Service
    def receive_event
    end

    def receive_push
    end

    def receive_issues
    end
  end

  def setup
    @svc = SchemaService
  end

  def test_supported_events
    assert_equal Service::ALL_EVENTS, @svc.supported_events.sort
  end
end

class CustomSchemaTest < DefaultSchemaTest
  class SchemaService < Service
    self.title = "Custom!"
    self.hook_name = "custom"

    string :abc
    password :def
    boolean :ghi

    white_list :abc, :ghi
  end

  def setup
    @svc = SchemaService
  end

  def test_title
    assert_equal 'Custom!', @svc.title
  end

  def test_hook_name
    assert_equal 'custom', @svc.hook_name
  end

  def test_schema
    assert_equal [
      [:string, :abc],
      [:password, :def],
      [:boolean, :ghi]], @svc.schema
  end

  def test_white_listed_attributes
    assert_equal %w(abc ghi), @svc.white_listed
  end
end

