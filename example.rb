require "proxsee"

listeners = Listeners.new(
  :default => "tcp://127.0.0.2:81",
  :other   => "tcp://127.0.0.2:82"
)

listeners.start
listeners.await

class ConfigTest < Proxsee::Test

  def test_default_backend
    assert_backend :default, "/"
  end

  def test_other_backend
    assert_backend :other, "/other"
  end

  def test_response_headers
    assert_header_exist "/other", "Foo"
    assert_header_equal "/other", "Foo", "bar"
  end

  def test_redir
    assert_proxy_redirect "http://nope", "/redir"
  end

  def test_redir_code
    assert_proxy_redirect_code 301, "/redir"
  end

  def test_request_headers_passed_to_backend

    request "/" do |res, backend|

      # WIP: Current way to check for a header in the proxy's request to
      # the backend. It is just a plain string for now...
      assert_match /Proxy: true/, backend.request,
        "Expected header and value Proxy: true to be sent to the backend"
    end

  end

end

