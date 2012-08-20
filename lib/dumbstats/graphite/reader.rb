require 'dumbstats/graphite'

module Dumbstats
  module Graphite
    class Reader
      include Initialization
      attr_accessor :running, :input, :output, :now
      # Agent to parse Graphite lines.
      # input.call should return String or nil (nil EOF).
      # Calls output.call({:path, :value, :time}).
      def run!
        @running = true
        while @running
          if line = input.call
            $stdout.puts "  line = #{line.inspect}" if @debug
            path, value, time, rest = line.split(/\s+/, 4)
            time &&= Time.at(time.to_i)
            time ||= self.now || Time.now
            time = time.call if Proc === time
            output.call(:path => path, :value => value.to_f, :time => time.utc)
          else
            @running = false
          end
        end
        self
      end
    end
  end
end

