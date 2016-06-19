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
    def assert_header_exist header_name, res, msg = nil
      assert_includes headers(res), header_name.downcase,
        msg || "Header #{header_name} expected to be present"
    end

    alias assert_header assert_header_exist

    def refute_header_exist header_name, res, msg = nil
      assert_includes headers(res), header_name.downcase,
        msg || "Header #{header_name} expected to be absent"
    end

    alias refute_header refute_header_exist

    def assert_header_equal header_name, expected, res, msg = nil
      header_value = headers(res)[header_name.downcase]

      assert_equal expected, [*header_value].join, msg || <<-MSG
        Expected header #{header_name} to be equal to #{expected}.
      MSG
    end

    def assert_redirect response
      assert_kind_of OpenURI::HTTPRedirect, response,
        "Response should be a redirect"
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

    def headers(res_or_req)
      res_or_req.respond_to?(:meta) ? res_or_req.meta : res_or_req.header
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

    # Default options to send to OpenURI::open_uri.

    OPEN_URI_OPTIONS = { redirect: false }.freeze

    # Makes a request to the proxy.
    #
    # Yields the response and the backend transaction (if it occured) to
    # the provided block.

    def request path, *args

      raise "Block required" unless block_given?

      request = Request.new(path, *args)

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
