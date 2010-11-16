require File.expand_path('../lib/amqp/version', __FILE__)

spec = Gem::Specification.new do |s|
  s.name = 'amqp'
  s.version = AMQP::VERSION
  s.date = '2009-12-29'
  s.summary = 'AMQP client implementation in Ruby/EventMachine'
  s.email = "amqp@tmm1.net"
  s.homepage = "http://amqp.rubyforge.org/"
  s.rubyforge_project = 'amqp'
  s.description = "An implementation of the AMQP protocol in Ruby/EventMachine for writing clients to the RabbitMQ message broker"
  s.has_rdoc = true
  s.rdoc_options = '--include=examples'

  # ruby -rpp -e' pp `git ls-files`.split("\n").grep(/^(doc|README)/) '
  s.extra_rdoc_files = [
    "README",
    "doc/EXAMPLE_01_PINGPONG",
    "doc/EXAMPLE_02_CLOCK",
    "doc/EXAMPLE_03_STOCKS",
    "doc/EXAMPLE_04_MULTICLOCK",
    "doc/EXAMPLE_05_ACK",
    "doc/EXAMPLE_05_POP",
    "doc/EXAMPLE_06_HASHTABLE"
  ]

  s.authors = ["Aman Gupta"]
  s.add_dependency('eventmachine', '>= 0.12.4')

  # ruby -rpp -e' pp `git ls-files`.split("\n") '
  s.files = [
    "README",
    "Rakefile",
    "amqp.gemspec",
    "amqp.todo",
    "doc/EXAMPLE_01_PINGPONG",
    "doc/EXAMPLE_02_CLOCK",
    "doc/EXAMPLE_03_STOCKS",
    "doc/EXAMPLE_04_MULTICLOCK",
    "doc/EXAMPLE_05_ACK",
    "doc/EXAMPLE_05_POP",
    "doc/EXAMPLE_06_HASHTABLE",
    "examples/amqp/simple.rb",
    "examples/mq/ack.rb",
    "examples/mq/clock.rb",
    "examples/mq/pop.rb",
    "examples/mq/hashtable.rb",
    "examples/mq/internal.rb",
    "examples/mq/logger.rb",
    "examples/mq/multiclock.rb",
    "examples/mq/pingpong.rb",
    "examples/mq/primes-simple.rb",
    "examples/mq/primes.rb",
    "examples/mq/stocks.rb",
    "lib/amqp.rb",
    "lib/amqp/version.rb",
    "lib/amqp/buffer.rb",
    "lib/amqp/client.rb",
    "lib/amqp/frame.rb",
    "lib/amqp/protocol.rb",
    "lib/amqp/server.rb",
    "lib/amqp/spec.rb",
    "lib/ext/blankslate.rb",
    "lib/ext/em.rb",
    "lib/ext/emfork.rb",
    "lib/mq.rb",
    "lib/mq/exchange.rb",
    "lib/mq/header.rb",
    "lib/mq/logger.rb",
    "lib/mq/queue.rb",
    "lib/mq/rpc.rb",
    "old/README",
    "old/Rakefile",
    "old/amqp-0.8.json",
    "old/amqp_spec.rb",
    "old/amqpc.rb",
    "old/codegen.rb",
    "protocol/amqp-0.8.json",
    "protocol/amqp-0.8.xml",
    "protocol/codegen.rb",
    "protocol/doc.txt",
    "research/api.rb",
    "research/primes-forked.rb",
    "research/primes-processes.rb",
    "research/primes-threaded.rb"
  ]
end
