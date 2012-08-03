require 'thread' # Queue
require 'socket'

module Dumbstats
  # Agent to dump Buckets into Graphite.
  class Graphite
    include Initialization

    attr_accessor :host, :port

    attr_accessor :prefix, :now

    attr_accessor :running, :thread

    def initialize *opts
      super
      @q = Queue.new
    end

    def socket
      unless @socket
        s = TCPSocket.new(:address => host, :port => port)
        @socket = s
      end
      @socket
    rescue ::Exception
      STDERR.puts "#{self} socket: failed #{err.inspect}"
      sleep 10
    end

    def add! name, value, now = nil
      now ||= self.now || Time.now.utc
      enqueue! "#{prefix}#{name} #{value} #{now.to_i}\n"
      self
    end

    def add_bucket! b, opts = nil
      opts ||= EMPTY_Hash
      now = opts[:now]
      now ||= self.now || Time.now.utc
      if b.rate?
        add! "#{b.name}.per_sec", v, now
      else
        b.to_a.each do | k, v |
          add! "#{b.name}.#{k}" v, now
        end
      end
    end

    def enqueue! data
      @q.enqueue data
    end

    def run!
      @running = true
      @thread = Thread.current
      while @running
        send! @q.dequeue
      end
      self
    end

    def send! data
      s = socket
      s.write data
    end

  end
end
