module SwaggerRails

  class TestCaseBuilder

    def initialize(path_template, http_method, swagger)
      @path_template = path_template
      @http_method = http_method
      @swagger = swagger
      @param_values = {}
    end

    def set(param_values)
      @param_values.merge!(param_values.stringify_keys)
    end

    def expect(status)
      @expected_status = status.to_s
    end

    def test_data
      operation = find_operation!
      parameters = operation['parameters'] || []
      responses = operation['responses']
      {
        path: build_path(parameters),
        params: build_params(parameters),
        headers: build_headers(parameters),
        expected_response: build_expected_response(responses)
      }
    end

    private

    def find_operation!
      keys = [ 'paths', @path_template, @http_method ]
      operation = find_hash_item!(@swagger, keys)
      operation || (raise MetadataError.new(keys))
    end

    def find_hash_item!(hash, keys)
      item = hash[keys[0]] || (return nil)
      keys.length == 1 ? item : find_hash_item!(item, keys.drop(1))
    end

    def build_path(parameters)
      param_values = param_values_for(parameters, 'path')
      @path_template.dup.tap do |template|
        template.prepend(@swagger['basePath'].presence || '')
        param_values.each { |name, value| template.sub!("\{#{name}\}", value) }
      end
    end

    def build_params(parameters)
      body_param_values = param_values_for(parameters, 'body')
      return body_param_values.values.first.to_json if body_param_values.any?
      param_values_for(parameters, 'query')
    end

    def build_headers(parameters)
      param_values_for(parameters, 'header')
        .merge({
          'CONTENT_TYPE' => 'application/json',
          'ACCEPT' => 'application/json'
        })
    end

    def build_expected_response(responses)
      status = @expected_status || responses.keys.find { |k| k.start_with?('2') }
      response = responses[status] || (raise MetadataError.new('paths', @path_template, @http_method, 'responses', status))
      {
        status: status.to_i,
        body: response_body_for(response)
      }
    end

    def param_values_for(parameters, location)
      applicable_parameters = parameters.select { |p| p['in'] == location }
      Hash[applicable_parameters.map { |p| [ p['name'], param_value_for(p) ] }]
    end

    def param_value_for(parameter)
      return @param_values[parameter['name']] if @param_values.has_key?(parameter['name'])
      return parameter['default'] unless parameter['in'] == 'body'
      schema = schema_for(parameter['schema'])
      schema_example_for(schema)
    end

    def response_body_for(response)
      return nil if response['schema'].nil?
      schema = schema_for(response['schema'])
      schema_example_for(schema)
    end

    def schema_for(schema_or_ref)
      return schema_or_ref if schema_or_ref['$ref'].nil?
      @swagger['definitions'][schema_or_ref['$ref'].sub('#/definitions/', '')]
    end

    def schema_example_for(schema)
      return schema['example'] if schema['example'].present?
      # If an array, try construct from the item example
      if schema['type'] == 'array' && schema['item'].present?
        item_schema = schema_for(schema['item'])
        return [ schema_example_for(item_schema) ]
      end
    end
  end

  class MetadataError < StandardError
    def initialize(*path_keys)
      path = path_keys.map { |key| "['#{key}']" }.join('')
      super("Swagger document is missing expected metadata at #{path}")
    end
  end
end
