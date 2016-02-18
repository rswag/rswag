require 'swagger_rails/testing/test_data_builder'

module SwaggerRails

  class TestVisitor

    def initialize(swagger)
      @swagger = swagger
    end

    def run_test(path_template, http_method, test, &block)
      builder = TestDataBuilder.new(path_template, http_method, @swagger)
      builder.instance_exec(&block) if block_given?
      test_data = builder.test_data

      test.send(http_method,
        test_data[:path],
        test_data[:params],
        test_data[:headers]
      )

      test.assert_response(test_data[:expected_status])
    end
  end
end

