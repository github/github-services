class Service
  module StructLoading
    def from(hash)
      new *members.map { |attr| hash[attr.to_s] }
    end
  end

  class Meta < Struct.new(:id, :sender, :repository)
    def self.from(hash)
      sender = User.from(hash['sender'])
      repository = Repository.from(hash['repository'])
      repository.owner = User.from(hash['user'])
      new hash['id'], sender, repository
    end
  end

  class User < Struct.new(:id, :login, :gravatar_id)
    extend StructLoading

    def url
      "https://github.com/#{login}"
    end
  end

  class Repository < Struct.new(:id, :source_id, :name, :owner)
    extend StructLoading

    def name_with_owner
      @name_with_owner ||= "#{owner.login}/#{name}"
    end

    def url
      owner.url << "/#{name}"
    end
  end
end
