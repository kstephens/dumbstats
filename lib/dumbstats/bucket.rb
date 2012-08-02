module Dumbstats
  # Collects details.
  class Bucket
    include Initialization

    def inspect
      to_s
    end

    KEYS =
    [
      :count,
      :min,
      :median,
      :avg,
      :stddev,
      :max,
      :sum,
      :dt,
    ]

    attr_accessor *KEYS
    attr_accessor :name, :values

    def initialize *args
      super
      @count = 0
    end

    def to_a
      h = [ ]
      KEYS.each do | k |
        v = instance_variable_get("@#{k}")
        h << [ k, v ] if v
      end
      h
    end

    def count! x
      @count += 1
      self
    end

    def count_only?
      ! @sum
    end

    def add! x
      @values << x if @values
      x = x.value if x.respond_to?(:value)
      unless @min
        @min = @max = x
      else
        @min = x if x < @min
        @max = x if x > @max
      end
      @sum ||= 0
      s = @sum += x
      c = @count += 1
      @avg = s.to_f / c
      self
    end

    def empty?
      ! @min || @max == @min
    end

    # Converts this to a rate over time.
    def rate! dt
      @dt = dt
      @min = @max = nil
      @avg = @sum.to_f / dt
      self
    end

    def finish!
      if @dt
        return self
      end
      if @count == 1
        @min = @max = @avg = nil
      end
      if @avg && @values && ! @values.empty?
        @values.sort!
        n = @values.size
        @median = @values[n / 2]
        v = @values.map{|e| e = (e.to_numeric - @avg); e * e}
        v.sort!
        s = 0
        v.each {|e| s += e }
        @stddev = Math.sqrt(s.to_f / n)
      end
      self
    end

    def histogram *opts
      opts << { :values => finish!.values }
      Histogram.new(*opts).generate
    end

    def h opts = nil
      h = histogram(opts)
      $stdout.puts "# #{self.class} #{@name}"
      to_a.each do | k, v |
        $stdout.puts "#{k.inspect}: #{v}" if v
      end
      $stdout.puts h * "\n"
      nil
    end

    def to_s opts = nil
      h({:width => 50, :height => 40}.update(opts || {}))
    end

    def inspect
      to_s
    end
  end # class
end # module

