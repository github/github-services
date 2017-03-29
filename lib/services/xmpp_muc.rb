require_relative 'xmpp_base'

class Service::XmppMuc < XmppHelper
    
  self.title = 'XMPP MUC'
  self.hook_name = 'xmpp_muc'
    
  string :JID, :room, :server, :nickname, :host, :port
  password :password, :room_password
  boolean :notify_fork, :notify_wiki, :notify_comments,
    :notify_issue, :notify_watch, :notify_pull

  white_list :room, :filter_branch, :JID, :room, :server, :nickname

  default_events :push, :commit_comment, :issue_comment,
    :issues, :pull_request, :pull_request_review_comment,
    :gollum
    
  def send_messages(messages)
    messages = Array(messages)
    setup_muc_connection()
    messages.each do |message|
        @muc.send ::Jabber::Message::new(::Jabber::JID.new(@data['muc_room']), message)
    end
    @muc.exit
    ensure
      @client.close if @client
  end
    
  def setup_muc_connection
      if (@muc.nil?)
        begin
          @client = ::Jabber::Client.new(::Jabber::JID::new(@data['JID']))
          @client.connect(@data['host'], @data['port'])
          @client.auth(@data['password'])
          ::Jabber::debug = true
          @muc = ::Jabber::MUC::MUCClient.new(@client)
          @muc.join(::Jabber::JID.new(@data['muc_room']), @data['room_password'])
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
      @muc
  end
    
  def set_muc_connection(muc)
      @muc = muc
  end
          
  def check_config(data)
    raise_config_error 'JID is required' if data['JID'].to_s.empty?
    raise_config_error 'Password is required' if data['password'].to_s.empty?
    raise_config_error 'Room is required' if data['room'].to_s.empty?
    raise_config_error 'Server is required' if data['server'].to_s.empty?
    data['nickname'] = 'github' if data['nickname'].to_s.empty?
    data.delete(:room_password) if data['room_password'].to_s.empty?
    data['muc_room'] = "#{data['room']}@#{data['server']}/#{data['nickname']}"

    data['port'] = check_port(data)
    data['host'] = check_host(data)

    @data = data
  end

  url 'http://xmpp.org/extensions/xep-0045.html'
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
