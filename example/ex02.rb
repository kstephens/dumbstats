$:.unshift File.expand_path("../../lib", __FILE__)

require 'rubygems'

require 'dumbstats/stats'
require 'dumbstats/histogram'
require 'pp'

class WeightedList
  attr_accessor :item_weight

  def initialize x = nil
    self.item_weight = x if x
  end

  def item_weight= x
    @sum = 0
    @weight_items = [ ]
    x.each do | k, w |
      @sum += w
      @weight_items << [ @sum, k ]
    end
    # pp @weight_items
  end

  def select r = nil
    r ||= DEFAULT_RAND
    i = r.call(@sum)
    wi = @weight_items.find{|wi| i < wi.first}
    # $stderr.puts "0 <= #{i} < @sum=#{@sum}  =>  #{wi.inspect}"
    wi[1]
  end
  DEFAULT_RAND = lambda { | m | rand m }
end

begin
  wl = WeightedList.new(:a => 2, :b => 3, :c => 5)

  stats = Dumbstats::Stats.new
  n = 10000
  n.times do | i |
    x = wl.select
    raise unless x
    stats.count!(x)
  end
  stats.put
  stats.each do | k, b |
    puts "  #{k}/#{n} = #{b.count / n.to_f}"
  end
end
