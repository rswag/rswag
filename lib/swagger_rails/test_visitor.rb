require 'singleton'

module SwaggerRails
  class TestVisitor

    include Singleton

    def act!(test, path_template, operation)
      params_data = params_data_for(test, operation[:parameters])

      path = build_path(path_template, params_data)
      body_or_params = build_body_or_params(params_data)
      headers = build_headers(params_data, operation[:consumes], operation[:produces])

      test.send(operation[:method], path, body_or_params, headers)
    end

    def assert!(test, expected_response)
      test.assert_response(expected_response[:status].to_i)
    end

    private

    def params_data_for(test, parameters)
      parameters.map do |parameter|
        parameter
          .slice(:name, :in)
          .merge(value: test.send(parameter[:name].to_s.underscore))
      end
    end

    def build_path(path_template, params_data)
      path = path_template.dup
      params_data.each do |param_data|
        path.sub!("\{#{param_data[:name]}\}", param_data[:value].to_s)
      end
      return path
    end

    def build_body_or_params(params_data)
      body_params_data = params_data.select { |p| p[:in] == 'body' }
      return body_params_data.first[:value].to_json if body_params_data.any?

      query_params_data = params_data.select { |p| p[:in] == 'query' }
      Hash[query_params_data.map { |p| [ p[:name], p[:value] ] }]
    end

    def build_headers(params_data, consumes, produces)
      header_params_data = params_data.select { |p| p[:in] == 'header' }
      headers = Hash[header_params_data.map { |p| [ p[:name].underscore.upcase, p[:value] ] }]

      headers['ACCEPT'] = consumes.join(';') if consumes.present?
      headers['CONTENT_TYPE'] = produces.join(';') if produces.present?

      return headers
    end
  end
end

#require 'swagger_rails/testing/test_case_builder'
#
#module SwaggerRails
#
#  class TestVisitor
#
#    def initialize(swagger)
#      @swagger = swagger
#    end
#
#    def run_test(path_template, http_method, test, &block)
#      builder = TestCaseBuilder.new(path_template, http_method, @swagger)
#      builder.instance_exec(&block) if block_given?
#      test_data = builder.test_data
#
#      test.send(http_method,
#        test_data[:path],
#        test_data[:params],
#        test_data[:headers]
#      )
#
#      test.assert_response(test_data[:expected_response][:status])
#      test.assert_equal(test_data[:expected_response][:body], JSON.parse(test.response.body))
#    end
#  end
#end
#
