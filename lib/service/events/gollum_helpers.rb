module Service::GollumHelpers
  include Service::HelpersWithMeta

  def pages
    payload['pages']
  end

  def summary_url
    if pages.size == 1
      pages[0]['html_url']
    else
      "#{payload['repository']['url']}/wiki"
    end
  end

  def summary_message
    if pages.size == 1
      single_page_summary_message
    else
      pages_summary_message
    end
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def single_page_summary_message
    summary = pages[0]['summary']

    '[%s] %s %s wiki page %s%s' % [
      repo.name,
      sender.login,
      pages[0]['action'],
      pages[0]['title'],
      summary ? ": #{summary}" : '',
    ]
  end

  def pages_summary_message
    counts = {}
    counts.default = 0
    pages.each { |page| counts[page['action']] += 1 }

    actions = []
    counts.each { |action, count| actions << "#{action} #{count}" }

    '[%s] %s %s wiki pages' % [
      repo.name,
      sender.login,
      actions.sort.to_sentence,
    ]
  end

  def self.sample_payload
    Service::HelpersWithMeta.sample_payload.merge(
      'pages' => [{
        'html_url' => 'https://github.com/mojombo/magik/wiki/Foo',
        'sha' => '0123456789abcdef0123456789abcdef01234567',
        'action' => 'created',
        'summary' => nil,
        'title' => 'Foo',
        'page_name' => 'Foo',
      }]
    )
  end
end
