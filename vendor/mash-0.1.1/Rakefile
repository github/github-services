require 'rubygems'
require './lib/mash.rb'
require 'spec/rake/spectask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "mash"
    gemspec.summary = "An extended Hash that gives simple pseudo-object functionality that can be built from hashes and easily extended."
    gemspec.description = "Mash is an extended Hash that gives simple pseudo-object functionality that can be built from hashes and easily extended."
    gemspec.email = "michael@intridea.com"
    gemspec.homepage = "http://github.com/mbleigh/mash"
    gemspec.authors = ["Michael Bleigh"]
    gemspec.files =  FileList["[A-Z]*", "{lib,spec}/**/*"] - FileList["**/*.log"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

task :default => :spec
desc "Run specs."
Spec::Rake::SpecTask.new("spec") do |t|
  t.spec_files = "spec/*_spec.rb"
  t.spec_opts = ['--colour', '--format specdoc']
end