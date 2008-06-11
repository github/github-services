$:.unshift *Dir["#{File.dirname(__FILE__)}/../vendor/**/lib"]
$:.unshift *Dir["#{File.dirname(__FILE__)}/../services"]

require 'spec'

Spec::Runner.configure do |config|
  config.mock_with :mocha
end

class ServiceRunner
  def initialize(service_name, data, payload)
    @service_name = service_name
    @data, @payload = data, payload
  end
  
  class << self
    attr_accessor :service_root
  end
  
  def invoke!
    self.instance_eval(service_script)
  end
  
  def service(name)
    raise invalid_service_message(name) unless name.eql?(@service_name)
    yield @data, @payload
  end
  
  private
    def service_script
      File.read(File.join(self.class.service_root, "#{@service_name}.rb"))
    end
    
    def invalid_service_message(name)
      "Could not find matching service to invoke. Expected '#{@service_name}', got '#{name}'."
    end
end

ServiceRunner.service_root = File.join(File.dirname(__FILE__), *%w[.. services])

def invoke_service(service_name, data, payload)
  ServiceRunner.new(service_name, data, payload).invoke!
end
