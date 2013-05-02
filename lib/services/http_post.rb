class Service::HttpPost < Service
  include HttpHelper

  alias receive_event deliver_event_payload
end

