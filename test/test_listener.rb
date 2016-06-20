gem "minitest"
require "minitest/autorun"
require "proxsee"

class TestListener < Minitest::Test

  attr_accessor :listener

  def setup
    self.listener = Listener.new "test", "http://localhost:34000"
  end

  def teardown
    listener.shutdown

    50.times do
      break unless listener.listening?
      sleep 0.005
    end

    if listener.listening?
      flunk "Unable to shut listener down after test run"
    end
  end

  def test_initialize
    assert_equal "localhost", listener.addr
    assert_equal 34000, listener.port

    assert listener.run?, "Should be allowed to run"

    refute listener.listening?, "Should not be activated"

    assert_empty listener.transactions, "No transactions should be present"
  end

  def test_shutdown
    assert listener.run?, "Should be runnable by default"

    listener.shutdown

    refute listener.run?, "Should no longer be runnable"
  end

  def test_default_response_immutable
    assert_equal 200, Listener.default_response.status

    Listener.default_response.status = 301

    assert_equal 200, Listener.default_response.status,
      "Fields on the default response should not be mutable"
  end

  def test_run
    refute listener.listening?, "Should not be listening until run is called"

    listener.run
    wait_for_server

    assert listener.listening?, "Server should be listening after 250ms."
  end

  def test_client_handler
    listener.run
    wait_for_server

    assert_equal Listener.default_response.body,
      open("http://localhost:34000/path").read,
      "Should get the default response from the listener"

    backend_transaction = listener.transactions.pop

    assert backend_transaction,
      "There should be a transaction logged after connecting to a listener"

    assert_equal "test", backend_transaction.name
    assert_equal "/path", backend_transaction.request.path

    assert_equal Listener.default_response.body,
      backend_transaction.response.body

    assert_empty listener.transactions
  end

  def test_custom_response
    out = Listener.default_response
    out.body = "test"

    listener.out = out
    listener.run
    wait_for_server

    assert_equal "test", open("http://localhost:34000").read,
      "Should get the default response from the listener"
  end

  def wait_for_server
    50.times do
      break if listener.listening?
      sleep 0.005
    end
  end

end
