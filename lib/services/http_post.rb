class Service::HttpPost < Service
  Service.services.delete(self)

  include HttpHelper

  alias receive_event deliver

  def receive_event
    deliver data['url'], :content_type => data['content_type'],
      :insecure_ssl => data['insecure_ssl'].to_i == 1, :secret => data['secret']
  end

  def original_body
    {:payload => payload, :event => event.to_s, :config => data,
     :guid => delivery_guid}
  end
end

