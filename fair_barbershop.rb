#!/usr/bin/env ruby

# == Synopsis
#   This is a sample description of the application.
#   Blah blah blah.
#
# == Examples
#   This command does blah blah blah.
#     fair_barbershop foo.txt
#
#   Other examples:
#     fair_barbershop -q bar.doc
#     fair_barbershop --verbose foo.html
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


require 'optparse'
require 'ostruct'
require 'date'


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

      opts.on('-v', '--version')    { output_version ; exit 0 }
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

      # TO DO - add additional options
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
      true if @arguments.length == 1
    end

    # Setup the arguments
    def process_arguments
      # TO DO - place in local vars, etc
    end

    def output_help
      output_version
    end

    def output_version
      puts "#{File.basename(__FILE__)} version #{VERSION}"
    end

    def process_command
      # TO DO - do whatever this app does

      #process_standard_input # [Optional]
    end

    def process_standard_input
      input = @stdin.read
      # TO DO - process input

      # [Optional]
      #@stdin.each do |line|
      #  # TO DO - process each line
      #end
    end
end


# TO DO - Add your Modules, Classes, etc


# Create and run the application
app = FairBarbershop.new(ARGV, STDIN)
app.run
