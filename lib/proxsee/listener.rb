class Listener

  attr_reader :backend, :addr, :port, :listening

  READ_BYTES = 1024

  def initialize backend, uri
    @backend = backend

    listen_uri = URI.parse uri
    @addr = listen_uri.host
    @port = listen_uri.port

    @listening = false
  end

  def listening?
    @listening
  end

  def run
    Thread.new do
      puts "Backend %s @ %s:%s" % [backend, addr, port]

      server = TCPServer.new addr, port

      out = "HTTP/1.0 200 OK\nOrig: true\nConnection: close\n\nbye"

      loop do
        @listening = true

        client = server.accept
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
        end

        client.close

        $results.push BackendTransaction.new(backend, r.join, out)
      end
    end
  end
end
