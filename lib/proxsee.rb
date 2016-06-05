require 'socket'
require 'open-uri'

require "proxsee/backend_transaction"
require "proxsee/listener"
require "proxsee/listeners"
require "proxsee/request"
require "proxsee/test"

Thread.abort_on_exception = true

module Proxsee
  VERSION = "1.0.0"
end
