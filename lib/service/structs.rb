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

  [
    User = Struct.new(:id, :login, :gravatar_id),
    Repository = Struct.new(:id, :source_id, :name, :owner),
  ].each do |struct|
    struct.extend StructLoading
  end
end
