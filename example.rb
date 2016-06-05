require "proxsee"

class ConfigTest < Proxsee::Test

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
    request_internal_redirect "/redir" do |res|
      assert_redirect_location "http://nope", res
      assert_redirect_status 301, res
    end
  end

  def test_redir_www
    request_internal_redirect Request.new("/www", "Host" => "example.com") do |res|
      assert_redirect_location "http://www.example.com/www", res
      assert_redirect_status 301, res
    end
  end

  def test_request_headers_passed_to_backend

    request "/" do |res, backend_capture|

      # WIP: Current way to check for a header in the proxy's request to
      # the backend. It is just a plain string for now...
      assert_match /Proxy: true/, backend_capture.request,
        "Expected header and value Proxy: true to be sent to the backend"
    end

  end

end

