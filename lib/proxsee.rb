require "open-uri"
require "webrick"

require "proxsee/assertions"
require "proxsee/backend_transaction"
require "proxsee/listener"
require "proxsee/listeners"
require "proxsee/test"

Thread.abort_on_exception = true

module Proxsee
  VERSION = "1.0.0"
end
