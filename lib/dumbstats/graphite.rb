require 'thread' # Queue
require 'socket'

module Dumbstats
  # Agent to dump Buckets into Graphite.
  class Graphite
    include Initialization

    attr_accessor :host, :port

    attr_accessor :prefix, :now

    attr_accessor :running, :thread

    attr_accessor :output_io

    def initialize *opts
      super
      @q = Queue.new
    end

    def encode_path name
      name.to_s.gsub(/[^a-z0-9_]/i, '-')
    end

    def add! name, value, now = nil, o = nil
      o ||= EMPTY_Hash
      now ||= self.now || Time.now.utc
      name = encode_path(name)
      enqueue! "#{prefix}#{o[:prefix]}#{name}#{o[:suffix]} #{value} #{now.to_i}\n"
      self
    end

    def add_bucket! b, opts = nil
      opts ||= EMPTY_Hash
      now = opts[:now]
      now ||= self.now || Time.now.utc
      if b.rate?
        add! b.name, b.rate, now, :prefix => opts[:prefix], :suffix => '.per_sec'
      else
        b.to_a.each do | k, v |
          next if a = opts[:ignore] and a.include?(k)
          add! b.name, v, now, :prefix => opts[:prefix], :suffix => '.' << encode_path(k)
        end
      end
    end

    def enqueue! data
      @q << data
    end

    def run!
      @running = true
      @thread = Thread.current
      while @running
        send! @q.pop
      end
      self
    end

    def send! data
      output_io.write data
    end

    def output_io
      @output_io || socket
    end

    def socket
      unless @socket
        s = TCPSocket.new(host || '127.0.0.1', port || 2003) # CORRECT DEFAULT PORT?
        @socket = s
      end
      @socket
    rescue ::Exception => exc
      STDERR.puts "#{self} socket: failed #{exc.inspect}\n  #{exc.backtrace * "\n  "}"
      sleep 10
      retry
    end

  end
end
