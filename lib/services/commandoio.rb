# Commando.io GitHub services integration
class Service::Commandoio < Service::HttpPost

  # Hook information
  self.title      = 'Commando.io'
  self.hook_name  = 'commandoio'

  # Support and maintainer information
  url           'https://commando.io'
  logo_url      'https://static.commando.io/img/favicon-250.png'

  supported_by  :web      => 'https://commando.io',
                :twitter  => '@commando_io',
                :email    => 'hello@commando.io'

  maintained_by :web      => 'https://unscramble.co.jp',
                :github   => 'aw',
                :twitter  => '@alexandermensa'

  # Form fields
  password      :api_token_secret_key

  string        :account_alias,
                :recipe,
                :server,
                :groups,
                :notes

  boolean       :halt_on_stderr

  # Only include these in the debug logs
  white_list    :account_alias,
                :recipe,
                :server,
                :groups,
                :halt_on_stderr

  def receive_event
    validate_config
    validate_server_groups

    url = "recipes/#{data['recipe']}/execute"

    http.basic_auth data['account_alias'], data['api_token_secret_key']

    http.ssl[:verify] = true
    http.url_prefix   = "https://api.commando.io/v1/"

    groups  = data['groups'].split(',').map {|x| x.strip }        if data['groups']

    params  = { :payload  => generate_json(payload) }

    params.merge!(:server          => data['server'])             if data['server']
    params.merge!(:groups          => groups)                     unless groups.nil?
    params.merge!(:halt_on_stderr  => data['halt_on_stderr'])     if config_boolean_true?('halt_on_stderr')
    params.merge!(:notes           => CGI.escape(data['notes']))  if data['notes']

    http_post url, params
  end

  # Validates the required config values
  #
  # Raises an error if a config value is invalid or empty
  def validate_config
    %w(api_token_secret_key account_alias recipe server groups).each {|key|
      raise_config_error("Invalid or empty #{key}") if is_error? key, config_value(key)
    }
  end

  # Validates the server and groups config values
  #
  # Raises an error if one or the other is missing, or if both are set (XOR)
  def validate_server_groups
    # XOR the server and groups
    raise_config_error("Server or Groups must be set, but not both.") unless config_value('server').empty? ^ config_value('groups').empty?
  end

  # Check if there's an error in the provided value
  #
  # Returns a boolean
  def is_error?(key, value)
    case key
    when 'api_token_secret_key' then true if  value.empty? ||
                                              value !~ /\Askey_[a-zA-Z0-9]+\z/

    when 'account_alias'        then true if  value.empty? ||
                                              value.length > 15 ||
                                              value !~ /\A[a-z0-9]+\z/

    when 'recipe'               then true if  value.empty? ||
                                              value.length > 25  ||
                                              value !~ /\A[a-zA-Z0-9_]+\z/

    when 'server'               then true if !value.empty? &&
                                              value !~ /\A[a-zA-Z0-9_]+\z/

    when 'groups'               then true if !value.empty? &&
                                              value !~ /\A[a-zA-Z0-9_\s\,]+\z/
    else
      false
    end
  end

end
