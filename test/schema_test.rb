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

  def test_url
    assert_nil @svc.url
  end

  def test_logo_url
    assert_nil @svc.logo_url
  end

  def test_maintainers
    assert_equal [], @svc.maintainers
  end

  def test_supporters
    assert_equal [], @svc.supporters
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
    title "Custom!"
    hook_name "custom"

    string :abc
    password :def
    boolean :ghi

    white_list :abc, :ghi

    url 'url'
    logo_url 'logo'

    maintained_by :email => 'abc@def.com',
      :web => 'http://def.com/support',
      :github => 'abc',
      :twitter => 'def'

    supported_by :email => 'abc@def.com',
      :web => 'http://def.com/support',
      :github => %w(abc def),
      :twitter => 'def'
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

  def test_maintainers
    maintainers = @svc.maintainers
    assert_contributor :email, 'abc@def.com', maintainers
    assert_contributor :web, 'http://def.com/support', maintainers
    assert_contributor :github, 'abc', maintainers
    assert_contributor :twitter, 'def', maintainers
    assert_equal 4, maintainers.size
  end

  def test_supporters
    supporters = @svc.supporters
    assert_contributor :email, 'abc@def.com', supporters
    assert_contributor :web, 'http://def.com/support', supporters
    assert_contributor :github, 'abc', supporters
    assert_contributor :github, 'def', supporters
    assert_contributor :twitter, 'def', supporters
    assert_equal 5, supporters.size
  end

  def test_url
    assert_equal 'url', @svc.url
  end

  def test_logo_url
    assert_equal 'logo', @svc.logo_url
  end

  def assert_contributor(contributor_type, value, contributors)
    assert contributors.detect { |c| c.class.contributor_type == contributor_type &&
                                     c.value == value }
  end
end

