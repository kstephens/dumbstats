module Dumbstats
  # A value that associates a numeric value with an aribitrary object.
  class Value < Struct.new(:value, :object)
    include Comparable
    def <=> x
      value <=> x.value
    end
    alias :to_numeric :value
  end
end # module

# Support for Value#to_numeric.
class Numeric
  def to_numeric
    self
  end
end

