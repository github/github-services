task :codegen do
  sh 'ruby codegen.rb > amqp_spec.rb'
  sh 'ruby amqp_spec.rb'
end

task :spec do
  sh 'bacon amqpc.rb'
end

task :test do
  sh 'ruby amqpc.rb'
end
