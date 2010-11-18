# Mash allows you to create pseudo-objects that have method-like
# accessors for hash keys. This is useful for such implementations
# as an API-accessing library that wants to fake robust objects
# without the overhead of actually doing so. Think of it as OpenStruct
# with some additional goodies.
#
# A Mash will look at the methods you pass it and perform operations
# based on the following rules:
# 
# * No punctuation: Returns the value of the hash for that key, or nil if none exists.
# * Assignment (<tt>=</tt>): Sets the attribute of the given method name.
# * Existence (<tt>?</tt>): Returns true or false depending on whether that key has been set.
# * Bang (<tt>!</tt>): Forces the existence of this key, used for deep Mashes. Think of it as "touch" for mashes.
#
# == Basic Example
#    
#   mash = Mash.new
#   mash.name? # => false
#   mash.name = "Bob"
#   mash.name # => "Bob"
#   mash.name? # => true
#
# == Hash Conversion  Example
#   
#   hash = {:a => {:b => 23, :d => {:e => "abc"}}, :f => [{:g => 44, :h => 29}, 12]}
#   mash = Mash.new(hash)
#   mash.a.b # => 23
#   mash.a.d.e # => "abc"
#   mash.f.first.g # => 44
#   mash.f.last # => 12
#
# == Bang Example
#
#   mash = Mash.new
#   mash.author # => nil
#   mash.author! # => <Mash>
#   
#   mash = Mash.new
#   mash.author!.name = "Michael Bleigh"
#   mash.author # => <Mash name="Michael Bleigh">
#
class Mash < Hash
  # If you pass in an existing hash, it will
  # convert it to a Mash including recursively
  # descending into arrays and hashes, converting
  # them as well.
  def initialize(source_hash = nil, &blk)
    deep_update(source_hash) if source_hash
    super(&blk)
  end
  
  class << self; alias [] new; end

  def id #:nodoc:
    self["id"] ? self["id"] : super
  end
  
  # Borrowed from Merb's Mash object.
  #
  # ==== Parameters
  # key<Object>:: The default value for the mash. Defaults to nil.
  #
  # ==== Alternatives
  # If key is a Symbol and it is a key in the mash, then the default value will
  # be set to the value matching the key.
  def default(key = nil) 
    if key.is_a?(Symbol) && key?(key) 
      self[key] 
    else 
      key ? super : super()
    end 
  end
  
  alias_method :regular_reader, :[]
  alias_method :regular_writer, :[]=
  
  # Retrieves an attribute set in the Mash. Will convert
  # any key passed in to a string before retrieving.
  def [](key)
    key = convert_key(key)
    regular_reader(key)
  end
  
  # Sets an attribute in the Mash. Key will be converted to
  # a string before it is set.
  def []=(key,value) #:nodoc:
    key = convert_key(key)
    regular_writer(key,convert_value(value))
  end
  
  # This is the bang method reader, it will return a new Mash
  # if there isn't a value already assigned to the key requested.
  def initializing_reader(key)
    return self[key] if key?(key)
    self[key] = Mash.new
  end
  
  alias_method :regular_dup, :dup  
  # Duplicates the current mash as a new mash.
  def dup
    Mash.new(self)
  end
  
  alias_method :picky_key?, :key?
  def key?(key)
    picky_key?(convert_key(key))
  end
  
  alias_method :regular_inspect, :inspect  
  # Prints out a pretty object-like string of the
  # defined attributes.
  def inspect
    ret = "<#{self.class.to_s}"
    keys.sort.each do |key|
      ret << " #{key}=#{self[key].inspect}"
    end
    ret << ">"
    ret
  end
  alias_method :to_s, :inspect
  
  # Performs a deep_update on a duplicate of the
  # current mash.
  def deep_merge(other_hash)
    dup.deep_merge!(other_hash)
  end
  
  # Recursively merges this mash with the passed
  # in hash, merging each hash in the hierarchy.
  def deep_update(other_hash)
    other_hash = other_hash.to_hash if other_hash.is_a?(Mash)
    other_hash = other_hash.stringify_keys
    other_hash.each_pair do |k,v|
      k = convert_key(k)
      self[k] = self[k].to_mash if self[k].is_a?(Hash) unless self[k].is_a?(Mash)
      if self[k].is_a?(Hash) && other_hash[k].is_a?(Hash)
        self[k] = self[k].deep_merge(other_hash[k]).dup
      else
        self.send(k + "=", convert_value(other_hash[k],true))
      end
    end
  end
  alias_method :deep_merge!, :deep_update
  
  # ==== Parameters
  # other_hash<Hash>::
  # A hash to update values in the mash with. Keys will be
  # stringified and Hashes will be converted to Mashes.
  #
  # ==== Returns
  # Mash:: The updated mash.
  def update(other_hash)
    other_hash.each_pair do |key, value|
      if respond_to?(convert_key(key) + "=")
        self.send(convert_key(key) + "=", convert_value(value))
      else
        regular_writer(convert_key(key), convert_value(value))
      end
    end
    self
  end
  alias_method :merge!, :update
  
  # Converts a mash back to a hash (with stringified keys)
  def to_hash
    Hash.new(default).merge(self)
  end
  
  def method_missing(method_name, *args) #:nodoc:
    if (match = method_name.to_s.match(/(.*)=$/)) && args.size == 1
      self[match[1]] = args.first
    elsif (match = method_name.to_s.match(/(.*)\?$/)) && args.size == 0
      key?(match[1])
    elsif (match = method_name.to_s.match(/(.*)!$/)) && args.size == 0
      initializing_reader(match[1])
    elsif key?(method_name)
      self[method_name]
    elsif match = method_name.to_s.match(/^([a-z][a-z0-9A-Z_]+)$/)
      default(method_name)
    else
      super
    end
  end
  
  protected
  
  def convert_key(key) #:nodoc:
    key.to_s
  end
  
  def convert_value(value, dup=false) #:nodoc:
    case value
      when Hash
        value = value.dup if value.is_a?(Mash) && dup
        value.is_a?(Mash) ? value : value.to_mash
      when Array
        value.collect{ |e| convert_value(e) }
      else
        value
    end
  end
end

class Hash
  # Returns a new Mash initialized from this Hash.
  def to_mash
    mash = Mash.new(self)
    mash.default = default
    mash
  end
  
  # Returns a duplicate of the current hash with
  # all of the keys converted to strings.
  def stringify_keys
    dup.stringify_keys!
  end
  
  # Converts all of the keys to strings
  def stringify_keys!
    keys.each{|k| 
      v = delete(k)
      self[k.to_s] = v
      v.stringify_keys! if v.is_a?(Hash)
      v.each{|p| p.stringify_keys! if p.is_a?(Hash)} if v.is_a?(Array)
    }
    self
  end
end