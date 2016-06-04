class Listener

  attr_reader :backend, :addr, :port, :listening

  READ_BYTES = 1024

  def initialize backend, uri
    @backend = backend

    listen_uri = URI.parse uri
    @addr = listen_uri.host
    @port = listen_uri.port

    @listening = false
    @run = true
  end

  def listening?
    @listening
  end

  def run?
    @run
  end

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

  def handle_client client
    out = "HTTP/1.0 200 OK\nOrig: true\nConnection: close\n\nbye"

    client.puts out

    r = []
    c = nil

    begin
      loop do
        r << (c=client.read_nonblock(READ_BYTES))
      end

    rescue IO::WaitReadable
      unless c
        IO.select([client])
        retry
      end

    rescue EOFError
    end

    client.close

    $results.push BackendTransaction.new(backend, r.join, out)
  end

  def shutdown
    @run = false
  end

end
