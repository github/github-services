module Service::PublicHelpers
  include Service::HelpersWithMeta

  def summary_url
    payload['repository']['url']
  end

  def summary_message
    "[%s] %s made the repository public" % [
      repo.name,
      sender.login,
    ]
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def self.sample_payload
    Service::HelpersWithMeta.sample_payload
  end
end
