class Listener

  attr_reader :backend, :addr, :port, :listening, :transactions

  # The HTTP response that will be provided when calling this listener,
  # in place of Listener.default_response.

  attr_writer :out

  def initialize backend, uri
    @backend = backend

    listen_uri = URI.parse uri
    @addr = listen_uri.host
    @port = listen_uri.port

    @listening = false
    @run = true

    @transactions = []

    @out = nil
  end

  class << self

    # The default HTTP response this listener will reply with when called.

    def default_response
      out = WEBrick::HTTPResponse.new WEBrick::Config::HTTP
      out.status = 200
      out.body = "bye"
      out
    end

  end

  alias name backend

  # Indicates if the listener is accepting connections.

  def listening?
    @listening
  end

  # Indicates whether the listener should be running.

  def run?
    @run
  end

  # Requests that the listener should stop listening.

  def shutdown
    @run = false
  end

  # The response that this listener will provide when called.

  def out
    @out or self.class.default_response
  end

  # Starts the accept loop. Listens on +port+, and replies to each
  # connection with the value in +out+.
  #
  # The accept loop runs until +shutdown+ is called.

  def run
    Thread.new do
      # puts "Backend %s @ %s:%s" % [backend, addr, port]

      server = TCPServer.new addr, port

      @listening = true

      while run?
        begin
          handle_client server.accept_nonblock

        rescue IO::WaitReadable, Errno::EINTR
          IO.select([server], nil, nil, 0.005)
        end
      end

      server.close

      @listening = false
    end
  end

  # Manages the client connection after is has been accepted by the
  # listener loop in +run+.
  #
  # Reads all bytes from the client, then sends the value in +out+
  # as the response.
  #
  # A BackendTransaction is created that captures all bytes received
  # and written, which is appended to the list of +transactions+.

  def handle_client client

    req = WEBrick::HTTPRequest.new WEBrick::Config::HTTP
    req.parse client

    @transactions.push BackendTransaction.new(backend, req, out)

    client.print out
    client.close
  end

end
