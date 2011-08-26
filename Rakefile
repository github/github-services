require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

task :default => :test

task :console do
  sh "irb -r ./config/load"
end

namespace :services do
  desc "Writes a JSON config to FILE || config/services.json"
  task :config do
    file = ENV["FILE"] || File.expand_path("../config/services.json", __FILE__)
    require File.expand_path("../config/load", __FILE__)
    services = Service.services.inject({}) do |memo, svc|
      memo.update svc.title => {
        :short_name => svc.hook_name,
        :schema     => svc.schema}
    end
    File.open file, 'w' do |io|
      io << Yajl.dump(services, :pretty => true)
    end
  end
end
