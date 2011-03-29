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

class FairBarbershop
  VERSION = '0.0.1'

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
      # TO DO - implement your real logic here
      if (@options.barbers > 0 and @options.chairs and @options.waiting > 0)
        true
      else
        puts "Cannot have a working barber shop with negative numbers.".color(:red)
        false
      end
    end

    # Setup the arguments
    def process_arguments
      @mutex1, @mutex2, @mutex3 = Mutex.new, Mutex.new, Mutex.new

      @max_capacity = ConditionVariable.new
      @sofa = ConditionVariable.new
      @barber_chair = ConditionVariable.new
      @customer_ready = ConditionVariable.new
      @payment = ConditionVariable.new
      @coord = ConditionVariable.new

      @finished = Array.new
      @leave_b_chair = Array.new
      @receipt = Array.new

    end

    def process_command
      # TO DO - do whatever this app does
    end

    def customer(id)
      customer_id = id

      # wait max_capacity
      # enter shop
      # wait mutex1
      # count += 1
      # customer_id = count
      # signal mutex1
      # wait sofa
      # sit on sofa
      # wait barber_chair
      # get up from sofa
      # signal sofa
      # sit in barber chair
      # wait mutex2
      # enqueue1 customer_id
      # signal customer_ready
      # signal mutex2
      # wait finished[customer_id]
      # signal leave_my_chair[customer_id]
      # pay
      # wait mutex3
      # enqueue2 customer_id
      # signal payment
      # signal mutex3
      # wait receipt[customer_id]
      # exit shop
      # signal max_capacity
    end

    def barber
      my_customer = 0

      while true do
        # wait customer_ready
        # wait mutex2
        # dequeue1 my_customer
        # signal mutex2
        # wait coord
        # cut hair
        # signal coord
        # signal finished[my_customer]
        # wait leave_my_chair[my_customer]
        # signal barber_chair
      end
    end

    def cashier
      my_customer = 0
      while true do
        # wait payment
        # wait mutex3
        # dequeue2 my_customer
        # signal mutex3
        # wait coord
        # accept pay
        # signal coord
        # signal receipt[my_customer]
      end
    end
end


# TO DO - Add your Modules, Classes, etc


# Create and run the application
app = FairBarbershop.new(ARGV, STDIN)
app.run
