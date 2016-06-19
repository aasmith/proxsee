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
    listeners.each(&:run)

    loop do
      break if listening?
      sleep 0.005
    end
  end

  def listening?
    listeners.all?(&:listening?)
  end

  def shutdown
    listeners.each(&:shutdown)

    loop do
      break if listeners.none?(&:listening?)
      sleep 0.005
    end
  end

  def results
    listeners.map { |l| l.transactions }.flatten
  end

  def find(backend)
    listeners.detect { |l| l.backend == backend }
  end
end
