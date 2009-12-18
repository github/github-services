require 'httparty'

module Tinder
  class Connection
    def initialize
      class << self
        include HTTParty

        headers 'Content-Type' => 'application/json'
      end
    end

    def metaclass
      class << self; self; end
    end

    def method_missing(*args, &block)
      metaclass.send(*args, &block)
    end
  end
end
