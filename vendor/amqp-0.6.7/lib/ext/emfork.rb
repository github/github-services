EMFORK = $0 == __FILE__

if EMFORK
  require 'rubygems'
end

require 'eventmachine'

#:stopdoc:

# helper to fork off EM reactors
def EM.fork num = 1, &blk
  unless @forks
    trap('CHLD'){
      pid = Process.wait
      p [:pid, pid, :died] if EMFORK
      block = @forks.delete(pid)
      EM.fork(1, &block)
    }

    trap('EXIT'){
      p [:pid, Process.pid, :exit] if EMFORK
      @forks.keys.each{ |pid|
        p [:pid, Process.pid, :killing, pid] if EMFORK
        Process.kill('USR1', pid)
      }
    }
    
    @forks = {}
  end

  num.times do
    pid = EM.fork_reactor do
      p [:pid, Process.pid, :started] if EMFORK

      trap('USR1'){ EM.stop_event_loop }
      trap('CHLD'){}
      trap('EXIT'){}

      blk.call
    end

    @forks[pid] = blk
    p [:children, EM.forks] if EMFORK
  end
end

def EM.forks
  @forks ? @forks.keys : []
end

if EMFORK
  p 'starting reactor'

  trap('INT'){ EM.stop_event_loop }

  EM.run{
    p [:parent, Process.pid]

    EM.fork(2){
      EM.add_periodic_timer(1) do
        p [:fork, Process.pid, :ping]
      end
    }

  }

  p 'reactor stopped'
end