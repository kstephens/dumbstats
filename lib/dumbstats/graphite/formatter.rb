require 'dumbstats/graphite'

module Dumbstats
  module Graphite
    class Formatter
      include Initialization

      # Called with String.
      attr_accessor :output

      # Unescaped Graphite path prefix.
      attr_accessor :prefix

      # Time to use for each #add!.
      attr_accessor :now

      # Output per_X records for rate Buckets.
      # per_sec is true by default.
      attr_accessor :per_sec, :per_min, :per_hr, :per_day

      def initialize *opts
        @per_sec = true
        super
      end

      def call item
        return if item == :flush
        add! item[:path], item[:value], item[:time], :encode_name => false
      end

      def add! name, value, now = nil, o = nil
        o ||= EMPTY_Hash
        now ||= self.now || Time.now.utc
        name = encode_path(name) unless o[:encode_name] == false
        output.call "#{prefix}#{o[:prefix]}#{name}#{o[:suffix]} #{value} #{now.to_i}\n"
        self
      end

      def add_bucket! b, opts = nil
        opts ||= EMPTY_Hash
        now = opts[:now] || opts[:time]
        now ||= self.now || Time.now.utc
        if b.rate?
          add! b.name, b.rate, now, opts.dup.update(:prefix => opts[:prefix], :suffix => '.per_sec') if @per_sec || opts[:per_sec]
          add! b.name, b.rate * 60 , now, opts.dup.update(:prefix => opts[:prefix], :suffix => '.per_min') if @per_min || opts[:per_min]
          add! b.name, b.rate * 3600, now, opts.dup.update(:prefix => opts[:prefix], :suffix => '.per_hr') if @per_hr || opts[:per_hr]
          add! b.name, b.rate * 86400, now, opts.dup.update(:prefix => opts[:prefix], :suffix => '.per_day') if @per_day || opts[:per_day]
        else
          b.to_a.each do | k, v |
            next if a = opts[:ignore] and a.include?(k)
            add! b.name, v, now, opts.dup.update(:prefix => opts[:prefix], :suffix => '.' << encode_path(k))
          end
        end
        self
      end

      def encode_path name
        name.to_s.gsub(/[^a-z0-9_]/i, '-')
      end
    end
  end
end

