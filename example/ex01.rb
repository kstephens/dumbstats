$:.unshift File.expand_path("../../lib", __FILE__)

require 'rubygems'

require 'dumbstats/stats'
require 'dumbstats/histogram'

begin
  stats = Dumbstats::Stats.new(:name => 'Roll 2x6')
  1000.times do | i |
    d1 = (i % 6) + 1
    d2 = ((i / 6) % 6) + 1
    stats.add!(:d1, d1)
    stats.add!(:d2, d2)
    stats.add!(:d6_2, d1 + d2)
  end
  puts stats[:d1].h
  puts stats[:d2].h
  puts stats[:d6_2].h
end
