require 'dumbstats/bucket'

module Dumbstats
  # Prepare statitical graph for text display.
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
      @min = x_to_v(0)
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
          @width = @max_min.to_i + 1
        else
          @max_min = @max_min.to_f
        end
      end
      @width_f = @width.to_f
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
end # module

