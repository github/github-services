require 'rubygems'
require 'bundler/setup'
$:.unshift *Dir["#{File.dirname(__FILE__)}/../vendor/internal-gems/**/lib"]

require File.expand_path("../../lib/github-services", __FILE__)
