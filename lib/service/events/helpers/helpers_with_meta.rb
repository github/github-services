module Service::HelpersWithMeta
  def repo
    @repo ||= self.class.objectify(payload['repository'])
  end

  def sender
    @sender ||= self.class.objectify(payload['sender'])
  end

  def self.sample_payload
    {
      "repository" => {
        "name"  => "grit",
        "url"   => "http://github.com/mojombo/grit",
        "owner" => { "login" => "mojombo" }
      },
      "sender" => { "login" => 'defunkt' }
    }
  end
end
