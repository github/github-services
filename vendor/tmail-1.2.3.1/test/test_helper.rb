# Add in the local library for the load path so we get that before any possible
# gem that is already installed.
require 'stringio'
$:.unshift File.dirname(__FILE__) + "/../lib"
$:.unshift File.dirname(__FILE__) + "/../lib/tmail"
require 'test/unit'
require 'extctrl'
require 'test/unit'
require 'tmail'
