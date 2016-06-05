require "minitest/autorun"

module Proxsee

  module ListenerHooks
    def before_setup
      listeners.start

      super
    end

    def after_teardown
      listeners.shutdown

      super
    end
  end

  module ListenerSetup
    def listeners(listener_spec)
      define_method :listeners do
        @listeners ||= Listeners.new listener_spec
      end
    end
  end

  module Assertions
    def assert_header_exist header_name, res
      assert_includes res.metas, header_name.downcase, "Header not present"
    end

    def assert_header_equal header_name, expected, res
      header_value = res.metas[header_name.downcase]

      assert_equal expected, [*header_value].join, <<-MSG
        Expected header #{header_name} to be equal to #{expected}.
      MSG
    end

    def assert_redirect_status code, response
      actual_code, _ = response.message.split(" ", 2)

      assert_equal code.to_s, actual_code, "Incorrect status code"
    end

    def assert_redirect_location to, response
      destination = response.uri

      assert_equal to, destination.to_s, "Invalid redirection target"
    end

    def assert_backend backend_name, backend_capture
      assert_equal backend_name, backend_capture.name
    end
  end

  class Test < Minitest::Test

    include ListenerHooks
    extend  ListenerSetup

    include Assertions

    # Default URI for making requests to the proxy. Override in the subclass,
    # if needed.

    def default_uri
      URI.parse("http://0:80")
    end

    # Raises an error if the given response is not a redirect.

    def ensure_redirect response
      unless OpenURI::HTTPRedirect === response
        raise "Response was not a redirect: #{response.message}"
      end
    end

    # Raises an error unless a backend capture is provided.

    def ensure_backend_captured backend_capture
      unless backend_capture
        raise <<-EOF
The proxy responded internally to a request instead of passing
it to a backend.
        EOF
      end
    end

    # Raises an error if a backend capture is provided.

    def ensure_no_backend_captured backend_capture
      if backend_capture
        raise <<-EOF.squeeze(" ").strip
A backend responded to a request that the proxy should have
been handled internally.
        EOF
      end
    end

    # Makes a request that should not go outside of the proxy to a backend,
    # and additionally should result in a redirect being returned.

    def request_internal_redirect request
      request_internal request do |res, backend_capture|
        yield res, backend_capture

        ensure_redirect res
      end
    end

    # Makes a request that should not go outside of the proxy to a backend.

    def request_internal request
      _request request do |res, backend_capture|
        yield res, backend_capture

        ensure_no_backend_captured backend_capture
      end
    end

    # Makes a request to the proxy that should be forwarded on to a backend.

    def request request
      _request request do |res, backend_capture|
        yield res, backend_capture

        ensure_backend_captured backend_capture
      end
    end

    # Default options to send to OpenURI::open_uri.

    OPEN_URI_OPTIONS = { redirect: false }.freeze

    # Don't use this directly.
    #
    # Makes a request to the proxy.
    #
    # Use `request` for a request that should go through to a
    # backend, and `internal_request` for one that should not.

    def _request path_or_request

      raise "Block required" unless block_given?

      request = Request.wrap path_or_request

      uri     = default_uri.merge(request.path)
      options = request.headers.merge OPEN_URI_OPTIONS

      res = begin
        open uri, options

      rescue OpenURI::HTTPRedirect, OpenURI::HTTPError
        # >= 3xx responses are raised as an exception. They are not,
        # so catch and return them.
        $!

      end

      # TODO check for more than 1 response
      cap = listeners.results[0]

      yield res, cap
    end

  end
end
