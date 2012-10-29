require 'socket'
require 'librevox/response'
require 'librevox/commands'
require 'librevox/applications'

require 'librevox/listener/inbound'

module Librevox
  class EventCommandSocket < Librevox::Listener::Inbound
    include Librevox::Commands

    def initialize args={}
      super
      @server   = args[:server] || "127.0.0.1"
      @port     = args[:port] || "8021"
      @auth     = args[:auth] || "ClueCon"
      @timeout  = args[:timeout] || nil
      @socket = nil
      connect(@timeout) unless args[:connect] == false
    end

    def api
      @command_delegate ||= Librevox::Listener::Base::CommandDelegate.new(self)
    end

    def bgapi
      @command_bg_delegate ||= Librevox::Listener::Base::CommandDelegate.new(self, "bgapi")
    end

    def command *args
      if check_connection
        p "#{super(*args).strip}\n\n"
        @socket.send "#{super(*args).strip}\n\n", 0
        read_response
      else
        return false
      end
    end

    def raw *args
      @socket.print *args
      read_response
    end

    def read_response
      response = Librevox::Response.new
      until response.command_reply? or response.api_response?
        response.headers = read_headers 
      end

      length = response.headers[:content_length].to_i
      response.instance_variable_set(:@content, length > 0 ? @socket.read(length) : "")
      response
    end

    def read_headers
      headers = ""

      while line = @socket.gets and !line.chomp.empty?
        headers += line
      end

      headers
    end


    def check_connection
      begin
        numread = @socket.recvfrom_nonblock(1)
        return self.connect(@timeout) if numread[0] == ""
      rescue Errno::EAGAIN => ex
        return self.connect(@timeout)
      rescue Exception => ex
        return self.connect(@timeout)
      end
      return true
    end
  end
end

