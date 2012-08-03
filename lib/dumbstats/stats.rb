require 'dumbstats'
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
  def clear!
    @s.clear
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

end # class
end # module

