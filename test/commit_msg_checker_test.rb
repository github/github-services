require File.expand_path('../helper', __FILE__)

class CommitMsgCheckerTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service(
      {'message_format' => '^add .*',
      'template' => email_template,
      'recipients' => 'foo@bar.com,john@smith.org'
      },
      push_payload)

    svc.receive_push

  end
  
  def service(*args)
    super Service::CommitMsgChecker, *args
  end

  def email_template
    tpl = <<HERE
{% for c in event.commits %}
  commit: {{ c.id }}
{% endfor %}
HERE
    return tpl
  end
  
end
    