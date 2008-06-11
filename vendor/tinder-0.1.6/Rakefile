require 'rubygems'
require 'hoe'
require File.join(File.dirname(__FILE__), 'lib', 'tinder', 'version')

# RDOC_OPTS = ['--quiet', '--title', "Tinder",
#     "--opname", "index.html",
#     "--line-numbers", 
#     "--main", "README",
#     "--inline-source"]
# 
# Generate all the Rake tasks

hoe = Hoe.new('tinder', ENV['VERSION'] || Tinder::VERSION::STRING) do |p|
  p.rubyforge_name = 'tinder'
  p.summary = "An (unofficial) Campfire API"
  p.description = "An API for interfacing with Campfire, the 37Signals chat application."
  p.author = 'Brandon Keepers'
  p.email = 'brandon@opensoul.org'
  p.url = 'http://tinder.rubyforge.org'
  p.test_globs = ["test/**/*_test.rb"]
  p.changes = p.paragraphs_of('CHANGELOG.txt', 0..1).join("\n\n")
  p.extra_deps << ['activesupport']
  p.extra_deps << ['hpricot']
end
