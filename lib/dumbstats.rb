require "dumbstats/version"

module Dumbstats
  module Initialization
    def update_from_hash! opts
      if opts
        opts.each do | k , v |
          send(:"#{k}=", v)
        end
      end
      self
    end

    def initialize *args
      super()
      opts = nil
      if args.size == 1
        opts = args.first
      else
        args.each do | a |
          opts ||= { }
          opts.update(a) if a
        end
      end
      update_from_hash! opts
    end
  end # module
end # module

require 'dumbstats/stats'

