class Yammer::MessageList < Array
  
  attr_reader :older_available, :ids
  
  def initialize(a, oa, c)
    super(a)
    @older_available = oa
    @client = c
    @ids = a.map {|m| m.id}.sort
  end
  
  def first
    self[0]
  end
  
  def last
    self[self.size - 1]
  end
  
end