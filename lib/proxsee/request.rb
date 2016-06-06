class Request

  attr_accessor :path

  attr_accessor :headers

  def initialize path, headers = {}
    @path = path
    @headers = headers
  end
end
