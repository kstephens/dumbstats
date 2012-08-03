require 'dumbstats/bucket'
require 'dumbstats/value'

module Dumbstats
# Collects stats by name into Buckets.
class Stats
  include Initialization

  attr_accessor :name
  attr_accessor :chain
  attr_accessor :verbose

  def inspect
    to_s
  end

  def initialize *opts
    super
    @s = { }
  end

  def stat k
    @s[k] ||= Bucket.new(:name => k, :values => [ ])
  end
  def [] k
    @s[k] || @s[k.to_sym]
  end
  def keys
    @s.keys.sort_by{|s| s.to_s}
  end
  def each
    keys.each do | k |
      yield k, @s[k]
    end
  end
  def method_missing sel, *args
    super unless args.empty? and ! block_given? and @s[sel]
  end

  def count! k, v = 1
    $stderr.puts "  count! #{k.inspect} #{v.inspect}" if @verbose
    b = stat(k)
    b.count! v
    @chain.count! k, v if @chain
    self
  end

  def add! k, v
    $stderr.puts "  add! #{k.inspect} #{v.inspect}" if @verbose
    b = stat(k)
    b.add! v
    @chain.add! k, v if @chain
    self
  end

  def add_delta! k, v0, v1
    $stderr.puts "  add_delta! #{k.inspect} #{v0.inspect}, #{v1.inspect}" if @verbose
    b = stat(k)
    b.add_delta! v0, v1
    @chain.add_delta! k, v0, v1 if @chain
    self
  end

  def finish!
    @s.values.each{|b| b.finish!}
    self
  end

  def put opts = { }
    o = opts[:output] || $stdout
    show_histogram = opts[:show_histogram]
    ks = @s.keys.sort_by{|e| e.to_s}
    ks.each do | k |
      c = @s[k]
      c.finish!
      if c.count_only?
        o.puts "    :'#{k}': #{c.count}"
        next
      end
      histogram = nil
      if show_histogram and values = c.values and ! values.empty?
        histogram = c.histogram(:width => 30, :height => 15)
        histogram = nil if histogram.empty?
      end
      o.puts "    #{k.to_sym.inspect}:"
      c.to_a.each do | k, v |
        o.puts "       #{k.to_sym.inspect}: #{v.inspect}"
      end
      if histogram
        o.puts "       :histogram:"
        histogram.each do | l |
          o.puts "         - #{l.inspect}"
        end
      end
    end
    self
  end

  def h
    put
    nil
  end

  # A Graph of values.
  class Graph < Bucket
    include Initialization
    attr_accessor :values, :width
    attr_accessor :values_are_integers

    def initialize *args
      super
      @force_min, @force_max = @min, @max
      if @values
        values = @values
        @values = [ ]
        values.each { | v | add! v }
        finish!
      end
      @width ||= 20
    end

    def fix_width!
      @width = 1 if @width < 1
      @max = x_to_v(@width + 1)
      @max_min = (@max - @min).to_f
      self
    end

    def finish!
      super
      return nil if empty?
      @min = @force_min if @force_min
      @max = @force_max if @force_max
      @max_min = @max - @min
      @values_are_integers = @values.all?{|e| Integer === e.to_numeric}
      if @values_are_integers
        if @width > @max_min
          @width = @max_min.to_i
        else
          @max_min = @max_min.to_f
        end
      end
      self
    end

    def sum!
      finish! unless @sum
      @sum
    end

    def percent value
      '%5.1f%%' % (value * 100 / sum!.to_f)
    end

    def bar value
      x = v_to_x(value).to_i
      binding.pry if x < 0
      if value > @min and x < 1
        bar = '.'
      else
        bar = "*" * x
      end
      bar = "#{bar}#{' ' * (@width - bar.size)}"
      bar
    end

    def v_to_x v
      (v - @min) * @width / @max_min # = x
    end

    def x_to_v x
      (x * @max_min / @width) + @min # = v
    end
  end
end # class
end # module

