task :codegen do
  sh 'ruby protocol/codegen.rb > lib/amqp/spec.rb'
  sh 'ruby lib/amqp/spec.rb'
end

task :spec do
  sh 'bacon lib/amqp.rb'
end

task :gem do
  sh 'gem build *.gemspec'
end

task :pkg => :gem
task :package => :gem