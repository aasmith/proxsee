class Listeners

  attr_reader :listeners

  attr_reader :backends

  def initialize(backends)
    @backends  = backends

    @listeners = backends.map do |backend, uri|
      Listener.new(backend, uri)
    end
  end

  def start
    listeners.each &:run
  end

  def await
    puts "waiting for listeners"
    loop do
      break if listeners.all? &:listening?
      sleep 0.1
    end
    puts "listeners ready"
  end
end
