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
