class MQ
  class Logger
    def initialize *args, &block
      opts = args.pop if args.last.is_a? Hash
      opts ||= {}

      printer(block) if block

      @prop = opts
      @tags = ([:timestamp] + args).uniq
    end

    attr_reader :prop
    alias :base :prop

    def log severity, *args
      opts = args.pop if args.last.is_a? Hash and args.size != 1
      opts ||= {}
      opts = @prop.clone.update(opts)

      data = args.shift

      data = {:type => :exception,
              :name => data.class.to_s.intern,
              :backtrace => data.backtrace,
              :message => data.message} if data.is_a? Exception

      (@tags + args).each do |tag|
        tag = tag.to_sym
        case tag
        when :timestamp
          opts.update :timestamp => Time.now
        when :hostname
          @hostname ||= { :hostname => `hostname`.strip }
          opts.update @hostname
        when :process
          @process_id ||= { :process_id => Process.pid,
                            :process_name => $0,
                            :process_parent_id => Process.ppid,
                            :thread_id => Thread.current.object_id }
          opts.update :process => @process_id
        else
          (opts[:tags] ||= []) << tag
        end
      end

      opts.update(:severity => severity,
                  :msg => data)

      print(opts)
      unless Logger.disabled?
        MQ.fanout('logging', :durable => true).publish Marshal.dump(opts)
      end

      opts
    end
    alias :method_missing :log

    def print data = nil, &block
      if block
        @printer = block
      elsif data.is_a? Proc
        @printer = data
      elsif data
        (pr = @printer || self.class.printer) and pr.call(data)
      else
        @printer
      end
    end
    alias :printer :print
    
    def self.printer &block
      @printer = block if block
      @printer
    end

    def self.disabled?
      !!@disabled
    end
    
    def self.enable
      @disabled = false
    end
    
    def self.disable
      @disabled = true
    end
  end
end