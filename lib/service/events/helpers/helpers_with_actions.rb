module Service::HelpersWithActions
  def action
    payload['action'].to_s
  end

  def opened?
    action == 'opened'
  end
end
