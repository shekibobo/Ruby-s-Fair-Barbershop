#!/usr/bin/env ruby

# == Synopsis
#   This is an implementation of Hilzer's Fair Barbershop solution in Ruby 1.9.2
#
# == Examples
#   This command does runs the program with all the defaults.
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
#
#   -b N, --barbers N   Set number of barbers
#   -c N, --chairs N    Set number of chairs
#   -w N, --waiting N   Set number of customers waiting
#   -r N, --registers N Set the number of registers available
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
#   Ruby Counting Semaphore Proposal Patch
#     http://redmine.ruby-lang.org/attachments/1109/final-semaphore.patch
#

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

    # colors for actors
    @color_barb = "#ff6600"
    @color_cust = "#af40f6"
    @color_cash = "#a3c5ef"
    @color_time = "#0fad3e"
    @color_err  = "#ff3333"

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
      if (@options.barbers > 0 and @options.chairs > 0 and
          @options.waiting > 0 and @options.registers > 0)
        true
      else
        puts "Cannot have a working barber shop without positive numbers.".color(@color_err)
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
          puts "Inconsistent data file. Using number of appointments in list.".color @color_err
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
      puts "Setting up shop...".color @color_barb

      @customers = []
      @barbers = []
      @cashiers = []

      puts "Shop is open for business.".color @color_barb
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

      puts "Closing time!".color @color_barb

    end

    #
    # Customers have a name, an id, and are schedule for a certain time slot
    # and an expected appointment duration.  If possible, enter the shop, sit on
    # the sofa (or wait to), wait for an open barber chair, sit in the barber
    # chair, get a cut, pay, get a receipt, then leave the shop.
    #
    # Currently supported: customer names, durations
    # TODO: customer arrival time
    #
    def customer(id, arrival_time=0, cut_duration=rand(5))
      # identify customers by name
      name = "#{@first_names.shuffle.first} #{@last_names.shuffle.first}".color("#ffc482") +
        "(#{id})".color(:yellow)

      @max_capacity.down
      enter_shop(name)

      @sofa.wait
      sit_on_sofa(name)

      @barber_chair.wait

      get_up_from_sofa(name)
      @sofa.signal

      sit_in_barber_chair(name)

      @mutex2.synchronize {
        # enqueue1 customer_id
        @cut_q << [id, name, cut_duration]
        @customer_ready.signal
      }

      @finished[id].wait
      @leave_b_chair[id].signal
      pay(name)

      @mutex3.synchronize {
        # enqueue2 customer_id
        @cash_q << [id, name]
        @payment.signal
      }

      @receipt[id].wait
      exit_shop(name)

      @max_capacity.up
    end

    #
    # The barber loops waiting for a customer to sit in his chair.
    # When the customer sits, cut their hair.  If there are no more customers
    # waiting, go ahead and call it quits.
    #
    def barber
      my_customer = 0
      c_name = ""
      cut_duration = 0

      while @shop_open do
        break if @customer_reservations < @barbers.size

        @customer_ready.wait

        @mutex2.synchronize {
          # dequeue1 my_customer
          my_customer, c_name,  cut_duration = @cut_q.pop
        }

        @coord.wait
        cut_hair(c_name, cut_duration)
        @coord.signal
        @finished[my_customer].signal
        @leave_b_chair[my_customer].wait
        @barber_chair.signal
      end

      mputs "Job's done!".color @color_barb
    end

    #
    # Wait for a customer to present payment, take their payment, and give them
    # a receipt. Exit if there are no more customers that need to pay.
    #
    def cashier
      my_customer = 0
      c_name = ""

      while @shop_open do
        break if @customer_reservations < @cashiers.size

        @payment.wait

        @mutex3.synchronize {
          # dequeue2 my_customer
          my_customer, c_name = @cash_q.pop
        }

        @coord.wait
        accept_pay(c_name)
        @coord.signal
        @receipt[my_customer].signal
      end

      mputs "Locking up the register.".color @color_cash
    end

    ## Here be the action methods (things the characters do)
    def enter_shop(name)
      mputs "#{name}" + " just walked into the shop.".color(@color_cust)
    end

    def sit_on_sofa(name)
      mputs "#{name}" + " sat on the couch.".color(@color_cust)
    end

    def get_up_from_sofa(name)
      mputs "#{name}" + " got up from the sofa.".color(@color_cust)
    end

    def sit_in_barber_chair(name)
      mputs "#{name}" + " sat in the barber chair.".color(@color_cust)
    end

    def pay(name)
      mputs "#{name}" + " pays the cashier.".color(@color_cust)
    end

    def exit_shop(name)
      mputs "#{name}" + " has left the shop.".color(@color_cust)
    end

    def cut_hair(name, duration)
      mputs "Cutting ".color(@color_barb) + "#{name}" + "'s hair.".color(@color_barb)
      sleep(duration)
      @mutex1.synchronize { @customer_reservations -= 1 } # decrement customer line
    end

    def accept_pay(name)
      mputs "Accepting payment from #{name}.".color(@color_cash)
    end

    # this is a synchronized print method using a mutex
    def mputs(str="")
      @mutex1.synchronize { puts "#{@time}: ".color(@color_time) + str }
    end
end

# Create and run the application
app = FairBarbershop.new(ARGV, STDIN)
app.run
