class Yammer::Message
  
  attr_reader :id, :url, :web_url, :replied_to_id, :thread_id,
              :body_plain, :body_parsed, :message_type, :client_type,
              :sender_id, :sender_type
  
  def initialize(m)
    @id = m['id']
    @url = m['url']
    @web_url = m['web_url']
    @replied_to_id = m['replied_to_id']
    @thread_id = m['thread_id']
    @body_plain = m['body']['plain']
    @body_parsed = m['body']['parsed']
    @message_type = m['message_type']
    @client_type = m['client_type']
    @sender_id = m['sender_id']
    @sender_type = m['sender_type']
    begin
      @created_at = m['created_at']
    rescue ArgumentError => e
      @created_at = nil
    end
  end
  
end
