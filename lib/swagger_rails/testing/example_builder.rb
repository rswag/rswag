module SwaggerRails
  
  class ExampleBuilder
    attr_reader :expected_status

    def initialize(path_template, http_method, swagger)
      @path_template = path_template
      @http_method = http_method
      @swagger = swagger
      @swagger_operation = find_swagger_operation!
      @expected_status = find_swagger_success_status!
      @param_values = {}
    end

    def expect(status)
      @expected_status = status
    end

    def set(param_values)
      @param_values.merge!(param_values.stringify_keys)
    end

    def path
      @path_template.dup.tap do |template|
        template.prepend(@swagger['basePath'].presence || '')
        path_params = param_values_for('path')
        path_params.each { |name, value| template.sub!("\{#{name}\}", value) }
      end
    end

    def params
      query_params = param_values_for('query')
      body_params = param_values_for('body')
      query_params.merge(body_params.values.first || {})
    end

    def headers
      param_values_for('header')
    end

    private

    def find_swagger_operation!
      find_swagger_item!('paths', @path_template, @http_method)
    end

    def find_swagger_success_status!
      path_keys = [ 'paths', @path_template, @http_method, 'responses' ]
      responses = find_swagger_item!(*path_keys)
      key = responses.keys.find { |k| k.start_with?('2') }
      key ? key.to_i : (raise MetadataError.new(path_keys.concat('2xx')))
    end

    def find_swagger_item!(*path_keys)
      item = @swagger
      path_keys.each do |key|
        item = item[key] || (raise MetadataError.new(*path_keys))
      end
      item
    end

    def param_values_for(location)
      params = (@swagger_operation['parameters'] || []).select { |p| p['in'] == location }
      Hash[params.map { |param| [ param['name'], value_for(param) ] }]
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
