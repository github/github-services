module Crack
  class ParseError < StandardError; end
end

require 'crack/core_extensions'
require 'crack/json'
require 'crack/xml'