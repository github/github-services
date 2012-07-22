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
  task :load do
    require File.expand_path("../config/load", __FILE__)
  end

  desc "Writes JSON config to FILE || config/services.json, Docs to DOCS"
  task :build => [:config, :docs]

  desc "Writes a JSON config to FILE || config/services.json"
  task :config => :load do
    file = ENV["FILE"] || File.expand_path("../config/services.json", __FILE__)
    services = []
    Service.services.each do |svc|
      services << {:name => svc.hook_name, :events => svc.default_events, :supported_events => svc.supported_events,
        :title => svc.title, :schema => svc.schema}
    end
    services.sort! { |x, y| x[:name] <=> y[:name] }
    data = {
      :metadata => { :generated_at => Time.now.utc },
      :services => services
    }
    puts "Writing config to #{file}"
    File.open file, 'w' do |io|
      io << Yajl.dump(data, :pretty => true)
    end
  end

  desc "Writes Docs to DOCS"
  task :docs => :load do
    return unless dir = ENV['DOCS']
    docs = Dir[File.expand_path("../docs/*", __FILE__)]
    docs.each do |path|
      name = File.basename(path)
      next if GitHubDocs.include?(name)
      new_name = dir.include?('{name}') ? dir.sub('{name}', name) : File.join(dir, name)
      new_dir = File.dirname(new_name)
      FileUtils.mkdir_p(new_dir)
      puts "COPY #{path} => #{new_name}"
      FileUtils.cp(path, new_name)
    end
  end

  require 'set'
  GitHubDocs = Set.new(%w(github_payload payload_data))
end
