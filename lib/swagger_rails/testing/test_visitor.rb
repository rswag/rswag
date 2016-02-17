require 'swagger_rails/testing/example_builder'

module SwaggerRails

  class TestVisitor

    def initialize(swagger)
      @swagger = swagger
    end

    def run_test(path_template, http_method, test, &block)
      example = ExampleBuilder.new(path_template, http_method, @swagger)
      example.instance_exec(&block) if block_given?

      test.send(http_method,
        example.path,
        example.params,
        example.headers
      )

      test.assert_response(example.expected_status)
    end
  end
end

