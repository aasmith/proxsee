require "proxsee"

class Example < Proxsee::Test

  listeners(
    :default => "tcp://127.0.0.2:81",
    :other   => "tcp://127.0.0.2:82"
  )

  def test_default_backend
    request "/" do |response, backend|
      assert_backend :default, backend
    end
  end

  def test_other_backend
    request "/other" do |response, backend|
      assert_backend :other, backend
    end
  end

  def test_response_headers
    request "/other" do |res|
      assert_header_exist "Foo", res
      assert_header_equal "Foo", "bar", res
    end
  end

  def test_redir
    request "/redir" do |res, backend|
      refute backend

      assert_redirect res
      assert_redirect_location "http://nope", res
      assert_redirect_status 301, res
    end
  end

  def test_redir_www
    request "/www", "Host" => "example.com" do |res, backend|
      refute backend

      assert_redirect res
      assert_redirect_location "http://www.example.com/www", res
      assert_redirect_status 301, res
    end
  end

  def test_no_redir_when_www
    headers = {
      "Host" => "www.example.com"
    }

    request "/www", headers do |res, backend|
      assert_backend :default, backend
    end
  end

  def test_denied
    request "/nope" do |res, backend|
      refute backend

      assert_match /^403 Forbidden/, res.message
    end
  end

  def test_request_headers_passed_to_backend
    request "/" do |res, backend_capture|
      assert_header_equal "Proxy", "true", backend_capture.request,
        "Expected header and value Proxy: true to be sent to the backend"
    end
  end

  def test_backend_response_headers_supressed

    # Respond with a 200 OK as normal, but with an extra header.

    out = Listener.default_response
    out["Secret"] = 42

    listener = listeners.find :default
    listener.out = out

    request "/" do |res, backend|
      assert_backend :default, backend

      assert_header_equal "Secret", "42", backend.response,
        "Expected secret value to be in backend response"

      assert_header_equal "Secret", "REDACTED", res,
        "Expected secret value to be redacted in proxy response"
    end
  end

  def test_backend_response_headers_deleted

    # Respond with a 200 OK as normal, but with an extra header.

    out = Listener.default_response
    out["Internal"] = "not-for-external-use"

    listener = listeners.find :default
    listener.out = out

    request "/" do |res, backend|
      assert_backend :default, backend

      assert_header_equal "Internal", "not-for-external-use", backend.response,
        "Expected secret value to be omitted from backend response"

      refute_header "Internal", res,
        "Expected internal header to not be in proxy response"
    end
  end

end
