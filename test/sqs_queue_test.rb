require File.expand_path('../helper', __FILE__)

class SqsQueueTest < Service::TestCase
  include Service::PushHelpers

  attr_reader :payload, :data

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new

    @old_data = {
      'aws_access_key' => '   AIQPJBLDKSU8SKLZNHGLQA',
      'aws_secret_key' => 'jaz8OQ72kzmblq9TYY28alqp9y7Zmvlsq9iJJqAA    ',
      'sqs_queue_name' => ' testQueue  '
    }
    @data = {
      'aws_sqs_arn' => "arn:aws:sqs:us-west-2:1234567890:testqueue",
      'aws_access_key' => '   AIQPJBLDKSU8SKLZNHGLQA',
      'aws_secret_key' => 'jaz8OQ72kzmblq9TYY28alqp9y7Zmvlsq9iJJqAA    '
    }
  end

  def test_strip_whitespace_from_form_data
    svc = service(@old_data, payload)
    assert_equal 'AIQPJBLDKSU8SKLZNHGLQA', svc.access_key
    assert_equal 'jaz8OQ72kzmblq9TYY28alqp9y7Zmvlsq9iJJqAA', svc.secret_key
    assert_equal 'testQueue', svc.queue_name
  end

  def test_aws_key_lengths
    svc = service(@old_data, payload)
    assert_equal 22, svc.access_key.length
    assert_equal 40, svc.secret_key.length
  end

  def service(*args)
    super Service::SqsQueue, *args
  end

  def test_sets_queue_name_with_arn
    svc = service(@data, payload)
    assert_equal 'testqueue', svc.queue_name
  end

  def test_sets_region_with_old_data
    svc = service(@old_data, payload)
    assert_equal 'us-east-1', svc.region
  end

  def test_sets_region_with_new_data
    svc = service(@data, payload)
    assert_equal 'us-west-2', svc.region
  end

end
