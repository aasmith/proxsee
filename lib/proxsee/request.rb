class Request

  attr_accessor :path

  attr_accessor :headers

  def initialize path, headers = {}
    @path = path
    @headers = headers
  end

  class << self
    def wrap path_or_request
      Request === path_or_request ? path_or_request : new(path_or_request)
    end
  end
end
