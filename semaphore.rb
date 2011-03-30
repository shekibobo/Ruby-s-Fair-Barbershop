class Semaphore
  require 'thread'

  def initialize(val=0)
    @counter = val
    @waitingList = []
  end

  def wait
    Thread.exclusive do
      # decrement and add to the waiting list
      @counter -= 1
      if @counter < 0
        @waitingList.push(Thread.current)
        Thread.stop
      end
      self # return itself
    end
  end

  def signal
    Thread.exclusive do
      begin
        @counter += 1
        if @counter <= 0
          thread = @waitingList.shift # FIFO => grab first added
          thread.wakeup if thread # if the shift produced a thread, wake it up
        end
      rescue ThreadError
        retry
      end
      self # return itself
    end
  end
end
