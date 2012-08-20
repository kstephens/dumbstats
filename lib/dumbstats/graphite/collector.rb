require 'dumbstats/graphite'

require 'dumbstats/graphite/reader'

module Dumbstats
  module Graphite
    class Collector
      include Initialization
      attr_accessor :files, :output, :items

      def initialize *opts
        @items = [ ]
        super
      end

      def run!
        @reader = Reader.new(:output => self)

        @running = true
        while @running && ! @files.empty?
          file = @files.shift
          fh = file == '-' ? $stdin : File.open(file)
          @reader.input = lambda do
            begin
              fh.readline
            rescue EOFError
              nil
            end
          end
          @reader.run!
          fh.close unless fh == $stdin
        end

        # Sort according to time.
        @items.sort{|a, b| a[:time] <=> b[:time]}
        @items.each do | i |
          @output.call(i)
        end
        @output.call(:flush)

        self
      end

      def call item
        return if item == :flush
        @items << item
        self
      end

      def main! args = nil
        require 'dumbstats/graphite/formatter'
        args ||= ARGV
        self.files = args.dup
        self.output = Formatter.new
        self.output.output = lambda do | item |
          $stdout.write item
        end
        self.run!
        self
      end
    end # class
  end # module
end # module


