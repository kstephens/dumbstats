require 'dumbstats/graphite'

module Dumbstats
  module Graphite
    # Summarize data into interval buckets.
    class Summarizer
      include Initialization
      attr_accessor :interval, :send_opts, :output

      def stats
        @stats ||= Dumbstats::Stats.new
      end

      def add! item
        if item == :flush
          send!
          return self
        end
        @t1 ||= item[:time] ||= Time.now.utc
        @t1 = item[:time] if @t1 < item[:time]
        stats.add! item[:path], item[:value]
        @t0 ||= @t1
        if (@dt = @t1 - @t0) >= @interval
          send!
        end
        self
      end
      alias :call :add!

      def send!
        # $stderr.puts "  send! dt = #{@dt}"
        stats.finish!
        stats.each do | k, b |
          @output.add_bucket! b, send_opts.update(:time => @t1)
        end
        @t0 = @t1
        @t1 = nil
        @stats.clear!
      end

      def main! args = nil
        require 'dumbstats/graphite/reader'
        require 'dumbstats/graphite/formatter'
        args ||= ARGV
        self.interval = 60
        self.send_opts = { :encode_name => false }
        reader = Reader.new
        fh = ARGF
        reader.input = lambda do
          begin
            fh.readline
          rescue EOFError
            nil
          end
        end
        reader.output = self
        self.output = Formatter.new
        self.output.output = lambda do | item |
          $stdout.write item
        end
        reader.run!
        self.send!
        self
      end
    end
  end
end

