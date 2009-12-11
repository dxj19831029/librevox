require 'fsr/cmd'

module FSR::Cmd
  class FSCTL < Command
    attr_reader :arguments

    def initialize(*args)
      @arguments = args
    end
  end
end
