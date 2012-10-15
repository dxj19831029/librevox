require 'socket'
require 'librevox/response'
require 'librevox/commands'
require 'librevox/applications'

module Librevox
  class CommandSocket
    include Librevox::Commands

    def initialize args={}
      @server   = args[:server] || "127.0.0.1"
      @port     = args[:port] || "8021"
      @auth     = args[:auth] || "ClueCon"
      @timeout  = args[:timeout] || nil

      connect(@timeout) unless args[:connect] == false
    end

    def connect(timeout=@timeout)
      #@socket = TCPSocket.open(@server, @port)

      addr = Socket.getaddrinfo(@server, nil)
      @socket = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)

      if timeout
        secs = Integer(timeout)
        usecs = Integer((timeout - secs) * 1_000_000)
        optval = [secs, usecs].pack("l_2")
        @socket.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
        @socket.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval
      end
      @socket.connect(Socket.pack_sockaddr_in(@port, addr[0][3]))

      @socket.send "auth #{@auth}\n\n", 0
      read_response
    end

    def api
      @command_delegate ||= Librevox::Listener::Base::CommandDelegate.new(self)
    end

    def bgapi
      @command_bg_delegate ||= Librevox::Listener::Base::CommandDelegate.new(self, "bgapi")
    end

    def command *args
      check_connection
      @socket.send "#{super(*args).strip}\n\n", 0
      read_response
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
        raise "Connection closed??" if numread[0] == ""
      rescue Errno::EAGAIN => ex
      end
    end
  end
end

