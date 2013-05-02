class Service::HttpPost < Service
  Service.services.delete(self)

  include HttpHelper

  alias receive_event deliver_event_payload
end

