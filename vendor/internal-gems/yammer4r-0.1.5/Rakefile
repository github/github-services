$:.unshift(File.join(File.dirname(__FILE__), 'lib'))
 
require 'rubygems'
require 'rake'
require 'spec/rake/spectask'
require 'yammer4r'

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*spec.rb']
end

task :default => [:spec]