require 'webrick'

class Listener

  attr_reader :backend, :addr, :port, :listening, :transactions

  # The HTTP response that will be provided when calling this listener,
  # in place of DEFAULT_RESPONSE.

  attr_writer :out

  READ_BYTES = 1024

  # The default HTTP response this listener will reply with when called.

  DEFAULT_RESPONSE = "HTTP/1.0 200 OK\nOrig: true\nConnection: close\n\nbye"

  def initialize backend, uri
    @backend = backend

    listen_uri = URI.parse uri
    @addr = listen_uri.host
    @port = listen_uri.port

    @listening = false
    @run = true

    @transactions = []

    @out = nil
    @server = nil
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
    @server.shutdown
  end

  # The response that this listener will provide when called.

  def out
    @out or DEFAULT_RESPONSE
  end

  # Starts the accept loop. Listens on +port+, and replies to each
  # connection with the value in +out+.
  #
  # The accept loop runs until +shutdown+ is called.

  def run
    Thread.new do
      @listening = true
      p Time.now
      @server = WEBrick::HTTPServer.new(:BindAddress => addr, :Port => port)
      @server.mount_proc "/" do |req, res|
        res.status = 200
        res.body = out
        @transactions.push BackendTransaction.new(backend, req, out)
      end
      @server.start
      @listening = false
    end
  end

end
