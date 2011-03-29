class Semaphore
  def initialize(val=1)
    @counter = val
    @waitingList = []
  end

  def wait
    Thread.critical = true
    # decrement and add to the waiting list
    @counter -= 1
    if @counter < 0
      @waitingList.push(Thread.current)
      Thread.stop
    end
    self # return itself
  # not sure what this does yet
  ensure
    Thread.critical = false
  end

  def signal
    Thread.critical = true
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
  ensure
    Thread.critical = false
  end
end
