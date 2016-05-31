require "minitest/autorun"

module Proxsee
  class Test < Minitest::Test

    make_my_diffs_pretty!

    def assert_header_exist path, header_name
      request path do |res, _|
        assert_includes res.metas, header_name.downcase, "Header not present"
      end
    end

    def assert_header_equal path, header_name, header_value
      request path do |res, _|
        assert_equal header_value, res.metas[header_name.downcase].join, <<-MSG
          Expected header #{header_name} to be equal to #{header_value}.
        MSG
      end
    end

    def assert_proxy_redirect_code code, path
      request_internal_redirect path do |res|
        actual_code, _ = res.message.split(" ", 2)

        assert_equal code.to_s, actual_code, "Incorrect status code"
      end
    end

    def assert_proxy_redirect to, path
      request_internal_redirect path do |res|
        destination = res.uri

        assert_equal to, destination.to_s, "Invalid redirection target"
      end
    end

    def assert_backend backend, path
      request path do |response, backend_capture|
        assert_equal backend, backend_capture.name
      end
    end

    # Provides the traffic captures from a transaction between the proxy and
    # the backend. This method will block until a capture appears.

    def get_backend_capture
      if $results.size > 1
        raise "FATAL: An assertion has not claimed a response from the stack!"
        abort
      end

      $results.pop
    end

    # In case a test leaves something on the results stack, remove it.
    #
    # This is expected to happen when a request that should be handled
    # by the proxy is instead passed to a backend.

    def clean_up
      $results.pop unless $results.empty?
    end

    # Default URI for making requests to the proxy. Override in the subclass,
    # if needed.

    def default_uri
      URI.parse("http://0:80")
    end

    def ensure_no_backend_responded
      unless $results.empty?
        raise <<-EOF.squeeze(" ").strip
        A backend responded to a request that the proxy should have
        been handled internally.
        EOF
      end
    end

    # A request that should be handled internally by the proxy. No requests
    # should be made to any backend.

    def ensure_internal &block
      block.call

      ensure_no_backend_responded

    rescue Exception
      clean_up
      raise

    end

    def ensure_redirect response
      unless OpenURI::HTTPRedirect === response
        raise "Response was not a redirect: #{response.status}"
      end
    end

    # Makes a request that should not go outside of the proxy to a backend.

    def request_internal path, &block
      ensure_internal do
        _request path, capture_backend: false do |res, _|
          block.call res
        end
      end
    end

    # Makes a request that results in a redirect inside the proxy and does
    # not contact a backend.

    def request_internal_redirect path, &block
      request_internal path do |res|
        ensure_redirect res
        block.call res
      end
    end

    # Makes a request to the proxy and expects a backend to respond.

    def request path, &block
      _request path, capture_backend: true, &block
    end

    # Don't use this directly.
    #
    # Makes a request to the proxy. Use either the `request` or
    # `request_internal` method as they clean up state correctly.

    def _request path, capture_backend:, &block
      raise "no block given" unless block_given?

      res = begin
        open default_uri.merge(path), redirect: false # never follow a 3xx.

      rescue OpenURI::HTTPRedirect # yes, this is weird
        $!
      end

      block.call res, capture_backend ? get_backend_capture : nil
    end

  end
end
