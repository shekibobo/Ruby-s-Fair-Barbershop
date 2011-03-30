class Semaphore
  require 'thread'

  def initialize(val=0)
    @counter = val
    @waiting_list = []
    @mutex = Mutex.new
  end

  def wait
    @mutex.synchronize do
      # decrement and add to the waiting list
      if (@counter -= 1) < 0
        @waiting_list.push Thread.current
        @mutex.sleep
      end
    end
  end

  def signal
    @mutex.synchronize do
      if (@counter += 1) <= 0
        begin
          t = @waiting_list.shift # FIFO => grab first added
          t.wakeup if t # if we popped a thread, wake it up
        rescue ThreadError
          puts "problem in signal".color(:pink)
          retry
        end
      end
    end
  end

  alias down wait
  alias up signal
end
