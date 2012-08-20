require 'dumbstats/graphite'
require 'dumbstats/graphite/formatter'

module Dumbstats
  class Graphite
  # Agent to dump Buckets into Graphite.
  class Agent
    include Initialization

    # Host/Port to Graphite.
    # host defaults to 127.0.0.1.
    # port defaults to 2003.
    attr_accessor :host, :port

    # Unescaped Graphite path prefix.
    attr_accessor :formatter, :prefix

    # Time to use for each #add!.
    attr_accessor :now

    # True if #run! is exceuting.
    # Can be set to false to terminate #run! gracefully.
    attr_accessor :running

    # The Thread in #run!.
    attr_accessor :thread

    # IO object to use instead of #socket.
    attr_accessor :output_io

    # IO object to log everything #send! to #socket.
    attr_accessor :log_io, :log_prefix

    def initialize *opts
      super
      @q = Queue.new
      @formatter ||= Formatter.new(:output => self, :prefix => @prefix)
    end

    def encode_path name
      @formatter.encode_path name
    end

    def add! *args
      @formatter.add! *args
      self
    end

    def add_bucket! *args
      @formatter.add_bucket! *args
      self
    end

    # Adds raw data to internal Queue.
    def enqueue! data
      @q << data
      self
    end
    alias :call :enqueue!

    # Consumes internal Queue, calls #send! till #running is false.
    # Typically run in a separate Thread.
    def run!
      @running = true
      @thread = Thread.current
      while @running
        send! @q.pop
      end
      self
    end

    # Sends data to #output_io and #log_io.
    def send! data
      send_output_io! data if @output_io || host
      send_log_io! data if log_io
      self
    end

    # Will rescue exceptions and close #socket.
    def send_output_io! data
      output_io.write data
      self
    rescue ::SystemExit, ::Interrupt, ::SignalException
      raise
    rescue ::Exception => exc
      $stderr.puts "#{Time.now.utc.iso8601} #{$$} #{self} ERROR in send_output_io! #{exc.inspect}"
      if @socket
        @socket.close rescue nil
        @socket = nil
      end
      self
    end

    # Will rescue IO errors.
    def send_log_io! data
      log_io.seek(0, IO::SEEK_END) rescue nil
      log_io.write "#{Time.now.utc.iso8601} #{log_prefix}#{data}"
      self
    rescue ::SystemExit, ::Interrupt, ::SignalException
      raise
    rescue ::Exception => exc
      $stderr.puts "#{Time.now.utc.iso8601} #{$$} #{self} ERROR in send_log_io! #{exc.inspect}"
      self
    end

    def output_io
      @output_io || socket
    end

    # Will retry after 10 sec if TCPSocket fails.
    def socket
      return @socket if @socket
      s = TCPSocket.new(host || '127.0.0.1', port || 2003) # CORRECT DEFAULT PORT?
      @socket = s
      @socket
    rescue ::SystemExit, ::Interrupt, ::SignalException
      raise
    rescue ::Exception => exc
      STDERR.puts "#{self} socket: failed #{exc.inspect}\n  #{exc.backtrace * "\n  "}"
      sleep 10
      retry
    end

  end # class
  end # module
end # module

