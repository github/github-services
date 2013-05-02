class Service::HttpPost < Service
  Service.services.delete(self)

  include HttpHelper

  alias receive_event deliver_event_payload

  def original_body
    {:payload => payload, :event => event.to_s, :config => data,
     :guid => delivery_guid}
  end
end

