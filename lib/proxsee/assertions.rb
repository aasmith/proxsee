module Proxsee
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

    def assert_redirect response, msg = nil
      assert_kind_of OpenURI::HTTPRedirect, response,
        msg || "Response should be a redirect"
    end

    def assert_redirect_status code, response, msg = nil
      actual_code, _ = response.message.split(" ", 2)

      assert_equal code.to_s, actual_code, msg || "Incorrect status code"
    end

    def assert_redirect_location to, response, msg = nil
      destination = response.uri

      assert_equal to, destination.to_s, msg || "Invalid redirection target"
    end

    def assert_backend backend_name, backend_capture, msg = nil
      assert_equal backend_name, backend_capture.name,
        msg || "Expected backend #{backend_name} to be equal to #{backend_capture.name}"
    end

    def headers(res_or_req)
      res_or_req.respond_to?(:meta) ? res_or_req.meta : res_or_req.header
    end

  end
end
