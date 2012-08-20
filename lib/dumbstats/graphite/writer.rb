require 'dumbstats/graphite'

module Dumbstats
  module Graphite
    class Writer
      include Initialization
      attr_accessor :formatter

      # Agent to parse Graphite lines.
      # Calls output.call({:path, :value, :time}).
      def call item
        output.call
        self
      end
      alias :call :add_item!
    end
  end
end

