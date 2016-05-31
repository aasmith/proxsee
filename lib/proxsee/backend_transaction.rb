class BackendTransaction

  ##
  # The name of the backend that was contacted.

  attr_reader :name

  ##
  # The request the proxy sent to the backend.

  attr_reader :request

  ##
  # The response the backend sent back to the proxy.

  attr_reader :response

  def initialize name, request, response
    @name = name

    @request  = request
    @response = response
  end

end
