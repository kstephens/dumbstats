require 'dumbstats/graphite'

module Dumbstats
  module Graphite
    # Summarize data into interval buckets.
    class Summarizer
      include Initialization
      attr_accessor :interval, :event_rates, :send_opts, :output
      attr_accessor :allow, :ignore
      attr_accessor :t0, :t1, :dt

      def initialize *opts
        @allow = [ ]; @ignore = [ ]
        super
      end

      def stats
        @stats ||= Dumbstats::Stats.new
      end

      def add! item
        if item == :flush
          @dt = nil
          send!
          return self
        end
        @t1 ||= item[:time] ||= Time.now.utc
        @t1 = item[:time] if @t1 < item[:time]
        stats.add! item[:path], item[:value]
        @t0 ||= @t1
        @dt = nil
        if dt >= @interval
          send!
        end
        self
      end
      alias :call :add!

      def dt
        @dt ||= @t1.to_f - @t0.to_f
      end

      def send!
        # $stderr.puts "  send! dt = #{@dt}"
        rates = [ ]
        stats.to_h.dup.each do | k, b |
          c = "#{k}.count"
          stats.count! c
          rates << c
        end
        rates.each do | k |
          stats[k].rate! dt
        end
        stats.finish!
        stats.each do | k, b |
          next if ignore.include?(k) && ! allow.include?(k)
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
        output.per_sec = output.per_min = output.per_hr = true
        output.output = lambda do | item |
          $stdout.write item
        end
        reader.run!
        self.send!
        self
      end
    end
  end
end

