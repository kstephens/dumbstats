require 'dumbstats/stats'
require 'dumbstats/graph'

gem 'terminal-table'
require 'terminal-table'

module Dumbstats
  # Renders a Histogram of values.
  class Histogram
    include Initialization

    attr_accessor :name, :values
    attr_accessor :min, :max
    attr_accessor :width, :height, :show_sum

    def initialize *args
      @min = @max = nil
      @show_sum = true
      super
      @width ||= 15
      @height ||= 20
    end

    def generate
      raise TypeError, "@values not set" unless @values
      return [ ] if @values.size < 2
      @x_graph = Graph.new(:min => @min, :max => @max, :values => @values, :width => @width)
      return [ ] if @x_graph.empty?
      # @x_graph.fix_width!

      @buckets = Hash.new { |h, k| b = Bucket.new; b.name = k; h[k] = b }
      @values.each do | v |
        next if @min and v < @min
        next if @max and v > @max
        i = @x_graph.v_to_x(v).to_i
        if i >= 0 and i < @x_graph.width
          @buckets[i].add! v
        end
      end

      cnt = @buckets.values.map { |b| b.count }
      cnt << 0
      @cnt_graph = Graph.new(:values => cnt, :width => @height)
      return [ ] if @cnt_graph.empty?
      # @cnt_graph.fix_width!

      if @show_sum
      sum = @buckets.values.map { |b| b.sum }
      sum << 0
      @sum_graph = Graph.new(:values => sum, :width => @height)
      # @sum_graph.fix_width!
      end

      # binding.pry

      rows = [ ]
      table =
        Terminal::Table.new() do | t |
        t.title = @name
        s = t.style
        s.border_x =
          s.border_y =
          s.border_i = ''
        s.padding_left = 0
        s.padding_right = 1

        # Header:
        h = [ '>=', '<', 'cnt', '%', "cnt h", "min", "avg", "max" ]
        align_right = [ 0, 1, 2, 3, 5, 6, 7 ]
        if @show_sum
          h.push('sum', '%', 'sum h')
          align_right.push(8, 9)
        end
        rows << h

        cnt_sum = sum_sum = 0
        @width.times do | i |
          x0 = @x_graph.x_to_v(i)
          x1 = @x_graph.x_to_v(i + 1)
          $stderr.puts "  i=#{i} x0=#{x0.inspect} x1=#{x1.inspect} #{@x_graph.min.inspect} #{@x_graph.max.inspect}"
          x0 = x0.to_i
          x1 = x1.to_i

          b = @buckets[i]
          b.finish!

          cnt_sum += b.count
          r = [ ]
          r << x0
          r << x1
          r << b.count
          r << @cnt_graph.percent(b.count)
          r << @cnt_graph.bar(b.count)
          r << b.min
          r << (b.avg && (@cnt_graph.values_are_integers ? b.avg.to_i : b.avg))
          r << b.max
          if @show_sum
            sum_sum += b.sum || 0
            r << b.sum
            r << @sum_graph.percent(b.sum || 0)
            r << @sum_graph.bar(b.sum || 0)
          end
          rows << r
        end

        f = [ '', '=', cnt_sum, '', '', '', '', '' ]
        if @show_sum
          f.push(sum_sum, '', '')
        end
        rows << f

        rows.each do | r |
          r.map! do | c |
            case c
            when nil
              ''
            when Integer
              thousands(c)
            else
              c
            end
          end
          t << r
        end

        raise unless h.size == f.size

        align_right.each { | c | t.align_column(c, :right) }
      end

      formatted = table.to_s.split("\n")

      formatted
    end

    def thousands x, sep = '_'
      x && x.to_s.reverse!.gsub(/(\d{3})/, "\\1#{sep}").reverse!.sub(/^(\D|\A)#{sep}/, '')
    end
  end # class

end # module

