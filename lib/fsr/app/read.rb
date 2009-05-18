require "fsr/app"
module FSR
    # http://wiki.freeswitch.org/wiki/Misc._Dialplan_Tools_read
  module App
    class Read < Application
      attr_reader :chan_var
      def initialize(sound_file, min = 0, max = 10, chan_var = "fsr_read_dtmf", timeout = 10000, terminators = ["#"])
        @sound_file, @min, @max, @chan_var, @timeout, @terminators = sound_file, min, max, chan_var, timeout, terminators
      end

      def arguments
        [@min, @max, @sound_file, @chan_var, @timeout, @terminators.join(",")]
      end

      def sendmsg
        "call-command: execute\nexecute-app-name: %s\nexecute-app-arg: %s\nevent-lock:true\n\n" % [app_name, arguments.join(" ")]
      end
      REGISTER_CODE = %q|
        def read(*args, &block)
          r = FSR::App::Read.new(*args)
          @read_var = "variable_#{r.chan_var}"
          r.sendmsg
          @queue << Proc.new { update_session } 
          @queue << block if block_given?
        end
      |
    end
    register(:read, Read, Read::REGISTER_CODE)


  end
end
