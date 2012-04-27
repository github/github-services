require File.expand_path('../helper', __FILE__)

class Service::CommitMsgChecker < Service
  def configure_delivery(config)
    Mail.defaults do
      delivery_method :file
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
    payload_file = File.new("github-event.js")
    hash = eval(payload_file.read)

    svc = service(hash['data'], hash['payload'])
    svc.configure_delivery([])

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
    