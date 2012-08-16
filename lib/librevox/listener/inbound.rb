require 'librevox/listener/base'

module Librevox
  module Listener
    class Inbound < Base
      def initialize args={}
        super

        @auth = args[:auth] || "ClueCon"
      end

      def post_init
        super
        send_data "auth #{@auth}\n\n"
        #send_data "event plain ALL\n\n"
      end

      # listen a particular channel's events
      def subscribe_to_channel_events(uuid)
        send_data "myevents #{uuid}\n\n"
      end
    end
  end
end
