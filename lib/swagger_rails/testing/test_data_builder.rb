module SwaggerRails
  
  class TestDataBuilder

    def initialize(path_template, http_method, swagger)
      @path_template = path_template
      @http_method = http_method
      @swagger = swagger
      @param_values = {}
      @expected_status = nil
    end

    def set(param_values)
      @param_values.merge!(param_values.stringify_keys)
    end

    def expect(status)
      @expected_status = status
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
      {}.tap do |params|
        params.merge!(param_values_for(parameters, 'query'))
        body_param_values = param_values_for(parameters, 'body')
        params.merge!(body_param_values.values.first) if body_param_values.any?
      end
    end

    def build_headers(parameters)
      param_values_for(parameters, 'header')
    end

    def build_expected_response(responses)
    end

    def param_values_for(parameters, location)
      applicable_parameters = parameters.select { |p| p['in'] == location }
      Hash[applicable_parameters.map { |p| [ p['name'], value_for(p) ] }]
    end

    def value_for(param)
      return @param_values[param['name']] if @param_values.has_key?(param['name'])
      return param['default'] unless param['in'] == 'body'
      schema_for(param['schema'])['example']
    end

    def schema_for(schema_or_ref)
      return schema_or_ref if schema_or_ref['$ref'].nil?
      @swagger['definitions'][schema_or_ref['$ref'].sub('#/definitions/', '')]
    end
  end

  class MetadataError < StandardError
    def initialize(*path_keys)
      path = path_keys.map { |key| "['#{key}']" }.join('')
      super("Swagger document is missing expected metadata at #{path}")
    end
  end
end
