#!/usr/bin/env ruby

# == Synopsis
#   This is a sample description of the application.
#   Blah blah blah.
#
# == Examples
#   This command does blah blah blah.
#     fair_barbershop
#
#   Other examples:
#     fair_barbershop -b 3 -c 7 -w 15
#     fair_barbershop -b 3 -c 7 -i customer_list.txt
#
# == Usage
#   fair_barbershop [options] source_file
#
#   For help use: fair_barbershop -h
#
# == Options
#   -h, --help          Displays help message
#   -v, --version       Display the version, then exit
#   -q, --quiet         Output as little as possible, overrides verbose
#   -V, --verbose       Verbose output
#   TO DO - add additional options
#   -b N, --barbers N   Set number of barbers
#   -c N, --chairs N    Set number of chairs
#   -w N, --waiting N   Set number of customers waiting
#
# == Author
#   Joshua Kovach
#
# == Copyright
#   Copyright (c) 2011 Joshua Kovach. Licensed under the MIT License:
#     http://www.opensource.org/licenses/mit-license.php
#
# == References
#   Ruby Command-line Argument skeleton code from Todd Werth
#     http://blog.toddwerth.com/entries/show/5


# TO DO - update Synopsis, Examples, etc

require 'rubygems'
require 'bundler/setup'

require 'optparse'
require 'ostruct'
require 'date'

require 'rainbow' # colorize output text
require 'thread'
require './semaphore.rb'

class FairBarbershop
  VERSION = '0.0.5'

  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin

    # Set defaults
    @options = OpenStruct.new
    @options.verbose = false
    @options.quiet = false

    # barbershop-specific defaults
    @options.barbers = 3
    @options.chairs = 7
    @options.waiting = 15
    @options.registers = 1

    # TO DO - add additional defaults

  end

  # Parse options, check arguments, then process the command
  def run

    if parsed_options? && arguments_valid?

      puts "Start at #{DateTime.now}\n\n" if @options.verbose

      output_options if @options.verbose # [Optional]

      process_arguments
      process_command

      puts "\nFinished at #{DateTime.now}" if @options.verbose

    end

  end

  protected

    def parsed_options?

      # Specify options
      opts = OptionParser.new
      opts.banner = "Usage: example.rb [options]"

      opts.separator ""
      opts.separator "Specific Options:"

      opts.on('-h', '--help')       { puts opts; exit 0 }
      opts.on('-V', '--verbose')    { @options.verbose = true }
      opts.on('-q', '--quiet')      { @options.quiet = true }

      # barbershop-specific options
      opts.separator ""
      opts.separator "Common Options:"

      opts.on('-b N', '--barbers N', Integer, "N barbers working (Default is 3)") do |n|
        @options.barbers = n
      end

      opts.on('-c N', '--chairs N', Integer, "N chairs (Default is 7)") do |n|
        @options.chairs = n
      end

      opts.on('-w N', '--waiting N', Integer, "N clients waiting (Default is 15)") do |n|
        @options.waiting = n
      end

      opts.on('-r N', '--registers N', Integer, "N registers operating") do |n|
        @options.registers = n
      end

      opts.on('-i FILE', '--input FILE', "Client Listing file (no default)") do |file|
        @options.input_file = File.open(file, "r")
      end

      # TO DO - add additional options

      # show usage if parsing fails
      begin
        opts.parse!(@arguments)
      rescue
        puts opts
        return false
      end

      process_options
      true
    end

    # Performs post-parse processing on options
    def process_options
      @options.verbose = false if @options.quiet
    end

    def output_options
      puts "Options:\n"

      @options.marshal_dump.each do |name, val|
        puts "  #{name} = #{val}"
      end
    end

    # True if required arguments were provided
    def arguments_valid?
      if (@options.barbers > 0 and @options.chairs and @options.waiting > 0)
        true
      else
        puts "Cannot have a working barber shop with negative numbers.".color(:red)
        false
      end
    end

    # Setup the arguments
    def process_arguments
      @mutex1 = Mutex.new
      @mutex2 = Mutex.new
      @mutex3 = Mutex.new

      @max_capacity = Semaphore.new @options.waiting
      @sofa = Semaphore.new 4
      @barber_chair = Semaphore.new @options.chairs
      @customer_ready = Semaphore.new
      @payment = Semaphore.new
      @coord = Semaphore.new @options.barbers

      @finished = []
      @leave_b_chair = []
      @receipt = []

      @cut_q = Queue.new
      @cash_q = Queue.new

      # read the input file
      @customer_schedule = []
      @customer_reservations = 50 # default number of customers
      unless @options.input_file.nil?
        # there are two ways to do this...
        # they way I'll handle this programatically:
        #   read in the first number. fine.  Use the actual number of lines
        #   as the number of customers in this program.
        @customer_reservations = @options.input_file.readline.to_i # first line
        @options.input_file.each do |line| # all the other lines into a 2darray
          @customer_schedule << line.split.map { |n| n.to_i }
        end

        if @customer_reservations != @customer_schedule.size
          puts "Inconsistent data file. Using number of appointments in list.".color :red
          @customer_reservations = @customer_schedule.size
        end
      end

      # set up customer names
      @first_names = %w(Jon Amy Erin Josh Matt Dave Paul Nick Brandon Sara
                        Allison Michelle Carly Rachel Mike)
      @last_names = %w(Johnson Smith Kovach Steigmeyer Zorro Apple Danger
                       Rodriguez Brando Carleson Thrace Adama Tyrol Gaeda)

      @time = 0
    end

    def process_command
      puts "Setting up shop...".color(:yellow)

      @customers = []
      @barbers = []
      @cashiers = []

      puts "Shop is open for business.".color(:green)
      @shop_open = true

      # start customer threads
      @customer_reservations.times do |i|
        @customers << Thread.new {
          if @customer_schedule.empty? # use the defaults
            customer i
          else  # get the entry time and duration from the file
            entry_time, cut_duration = @customer_schedule.pop
            customer i, entry_time, cut_duration
          end
        }

        # setup semaphores for this customer thread
        @finished << Semaphore.new
        @leave_b_chair << Semaphore.new
        @receipt << Semaphore.new
      end

      # start barber threads
      @options.barbers.times do |i|
        @barbers << Thread.new { barber }
      end

      # start cashier threads
      @options.registers.times do |i|
        @cashiers << Thread.new { cashier }
      end

      @t_timer = Thread.new {
        while @shop_open do
          sleep(1)
          @time += 1
        end
      }

      @customers.each do |t| # wait until all customers have had haircuts
        t.join
      end

      @shop_open = false

      @barbers.each do |t|
        t.join
      end

      @cashiers.each do |t|
        t.join
      end

      puts "Closing time!".color :green

    end

    def customer(id, arrival_time=0, cut_duration=rand(5))
      name = "#{@first_names.shuffle.first} #{@last_names.shuffle.first}".color(:green) +
        "(#{id})".color(:yellow)

      # @mutex1.synchronize {
      #   puts "#{name} is waiting for a haircut."
      # }

      # wait max_capacity
      @max_capacity.down
      # enter shop
      enter_shop(name)
      # wait mutex1
      # @mutex1.synchronize {
        ## define the customer number by non-encapsulated means ##
        ## I don't think this is needed here ##
        # count += 1
        # customer_id = count
        # signal mutex1
      # }
      # wait sofa
      @sofa.wait
      # sit on sofa
      sit_on_sofa(name)
      # wait barber_chair
      @barber_chair.wait
      # get up from sofa
      get_up_from_sofa(name)
      # signal sofa
      @sofa.signal
      # sit in barber chair
      sit_in_barber_chair(name)
      # wait mutex2
      @mutex2.synchronize {

        # enqueue1 customer_id
        @cut_q << [id, name, cut_duration]
        # signal customer_ready
        @customer_ready.signal
        # signal mutex2
      }
      # wait finished[customer_id]
      @finished[id].wait
      # signal leave_my_chair[customer_id]
      @leave_b_chair[id].signal
      # pay
      pay(name)
      # wait mutex3
      @mutex3.synchronize {
        # enqueue2 customer_id
        @cash_q << [id, name]
        # signal payment
        @payment.signal
        # signal mutex3
      }
      # wait receipt[customer_id]
      @receipt[id].wait
      # exit shop
      exit_shop(name)
      # signal max_capacity
      @max_capacity.up
    end

    def barber
      my_customer = 0
      c_name = ""
      cut_duration = 0

      while @shop_open do
        break if @customer_reservations < @barbers.size
        # wait customer_ready
        @customer_ready.wait
        # wait mutex2
        @mutex2.synchronize {
          # dequeue1 my_customer
          my_customer, c_name,  cut_duration = @cut_q.pop
          # signal mutex2
        }
        # wait coord
        @coord.wait
        # cut hair
        cut_hair(c_name, cut_duration)
        # signal coord
        @coord.signal
        # signal finished[my_customer]
        @finished[my_customer].signal
        # wait leave_my_chair[my_customer]
        @leave_b_chair[my_customer].wait
        # signal barber_chair
        @barber_chair.signal
      end

      @mutex1.synchronize { puts "Job's done!".color :yellow }
    end

    def cashier
      my_customer = 0
      c_name = ""
      while @shop_open do
        break if @customer_reservations < @cashiers.size
        # wait payment
        @payment.wait
        # wait mutex3
        @mutex3.synchronize {
          # dequeue2 my_customer
          my_customer, c_name = @cash_q.pop
          # signal mutex3
        }
        # wait coord
        @coord.wait
        # accept pay
        accept_pay(c_name)
        # signal coord
        @coord.signal
        # signal receipt[my_customer]
        @receipt[my_customer].signal
      end

      @mutex1.synchronize { puts "Locking up the register.".color :yellow }
    end

    ## Here be the action methods (things the characters do)
    def enter_shop(name)
      @mutex1.synchronize {
        puts "#{name} just walked into the shop.".color(:blue)
      }
    end

    def sit_on_sofa(name)
      @mutex1.synchronize {
        puts "#{name} sat on the couch.".color(:blue)
      }
    end

    def get_up_from_sofa(name)
      @mutex1.synchronize {
        puts "#{name} got up from the sofa.".color(:blue)
      }
    end

    def sit_in_barber_chair(name)
      @mutex1.synchronize {
        puts "#{name} sat in the barber chair.".color(:blue)
      }
    end

    def pay(name)
      @mutex1.synchronize {
        puts "#{name} pays the cashier.".color(:blue)
      }
    end

    def exit_shop(name)
      @mutex1.synchronize {
        puts "#{name} has left the shop.".color(:blue)
      }
    end

    def cut_hair(name, duration)
      @mutex1.synchronize {
        puts "Cutting #{name}'s hair.".color(:cyan)
      }
      sleep(duration)
      @mutex1.synchronize { @customer_reservations -= 1 } # decrement customer line
    end

    def accept_pay(name)
      @mutex1.synchronize {
        puts "Accepting payment from #{name}.".color(:yellow)
      }
    end
end

# Create and run the application
app = FairBarbershop.new(ARGV, STDIN)
app.run
