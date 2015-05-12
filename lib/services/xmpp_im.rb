require_relative 'xmpp_base'

class Service::XmppIm < XmppHelper
    
  self.title = 'XMPP IM'
  self.hook_name = 'xmpp_im'
    
  string :JID, :receivers, :host, :port
  password :password
  boolean :notify_fork, :notify_wiki, :notify_comments,
    :notify_issue, :notify_watch, :notify_pull

  white_list :filter_branch, :JID, :receivers

  default_events :push, :commit_comment, :issue_comment,
    :issues, :pull_request, :pull_request_review_comment,
    :gollum
 
  def send_messages(messages)
    messages = Array(messages)
    setup_connection()
    @receivers.each do |receiver|
      messages.each do |message|
        @client.send ::Jabber::Message::new(receiver, message)
      end
    end
    ensure
      @client.close if @client
  end
    
  def setup_connection
      if (@client.nil?)
        begin
          @client = ::Jabber::Client.new(::Jabber::JID::new(@data['JID']))
          @client.connect(@data['host'], @data['port'])
          @client.auth(@data['password'])
          ::Jabber::debug = true
        rescue ::Jabber::ErrorResponse
          raise_config_error 'Error response'
        rescue ::Jabber::ClientAuthenticationFailure
          raise_config_error 'Authentication error'
        rescue ::Jabber::JabberError
          raise_config_error "XMPP Error: #{$!.to_s}"
        rescue StandardError => e
          raise_config_error "Unknown error: #{$!.to_s}"
        end
      end
      @client
  end
    
  def set_connection(client)
      @client = client
  end
          
  def check_config(data)
    raise_config_error 'JID is required' if data['JID'].to_s.empty?
    raise_config_error 'Password is required' if data['password'].to_s.empty?
    raise_config_error 'Receivers list is required' if data['receivers'].to_s.empty?
    @receivers = Array.new
    data['receivers'].split().each do |jid|
      begin
        @receivers.push(::Jabber::JID.new(jid))
      rescue Exception => e
        raise_config_error 'Illegal receiver JID'
      end
    end
    data['port'] = check_port(data)
    data['host'] = check_host(data)
    @data = data
  end

  url 'http://xmpp.org/rfcs/rfc6121.html'
  logo_url 'http://xmpp.org/images/xmpp-small.png'

  # lloydwatkin on GitHub is <del>pinged</del> contacted for any bugs with the Hook code.
  maintained_by :github => 'lloydwatkin'

  # Support channels for user-level Hook problems (service failure,
  # misconfigured
  supported_by :web => 'http://github.com/lloydwatkin/github-services/issues',
               :email => 'lloyd@evilprofessor.co.uk',
               :twitter => 'lloydwatkin',
               :github => 'lloydwatkin'
end
