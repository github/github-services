require File.expand_path('../helper', __FILE__)

class Service::CommitMsgChecker < Service
  def configure_delivery(config)
    Mail.defaults do
      delivery_method :test
    end
    @@mail_configured = true
  end

  def mail_from
    "john@smith.org"
  end

  def secret_header
    {"myheader" => "abc"}
  end
  
end

class CommitMsgCheckerTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
#    payload_file = File.new("github-event.js")
    payload_file = File.new("docs/github_payload")
    payload = eval(payload_file.read)
    
    svc = service({
      'message_format' => '\[#WEB-\d{1,5} status:\d+ resolution:\d+\] .*$',
      'recipients' => "a@b.fi, c@d.fi"
    }, payload['payload'])
    svc.configure_delivery([])

    svc.receive_push
    
    assert_equal 1, Mail::TestMailer.deliveries.length
    m = Mail.new(Mail::TestMailer.deliveries.shift)    
    assert_equal "[mojombo/grit] commit message format is invalid", m.subject
    assert_equal ["tom@mojombo.com"], m.to
    assert_equal ["a@b.fi", "c@d.fi"], m.cc
    assert_equal 2, m.body.to_s.scan(%r{^commit: http://github.com/mojombo/grit/commit/\w+}).length
    assert_match "commit/5057e76a11abd02e83b7d3d3171c4b68d9c88480", m.body.to_s
    assert_match "commit/a47fd41f3aa4610ea527dcc1669dfdb9c15c5425", m.body.to_s
    assert_no_match %r{commit/06f63b43050935962f84fe54473a7c5de7977325}, m.body.to_s
    
    #puts m
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
    