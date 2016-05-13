module SwaggerRails
  class TestVisitor

    def initialize(swagger_doc)
      @swagger_doc = swagger_doc
    end

    def submit_request!(test, metadata)
      params_data = params_data_for(test, metadata[:parameters])

      path = build_path(metadata[:path_template], params_data)
      body_or_params = build_body_or_params(params_data)
      headers = build_headers(params_data, metadata[:consumes], metadata[:produces])

      test.send(metadata[:http_verb], path, body_or_params, headers)
    end

    def assert_response!(test, metadata)
      test.assert_response(metadata[:response_code].to_i)
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
      path_params_data = params_data.select { |p| p[:in] == :path }

      path_template.dup.tap do |path|
        path_params_data.each do |param_data|
          path.sub!("\{#{param_data[:name]}\}", param_data[:value].to_s)
        end
        path.prepend(@swagger_doc[:basePath] || '')
      end
    end

    def build_body_or_params(params_data)
      body_params_data = params_data.select { |p| p[:in] == :body }
      return body_params_data.first[:value].to_json if body_params_data.any?

      query_params_data = params_data.select { |p| p[:in] == :query }
      Hash[query_params_data.map { |p| [ p[:name], p[:value] ] }]
    end

    def build_headers(params_data, consumes, produces)
      header_params_data = params_data.select { |p| p[:in] == :header }
      headers = Hash[header_params_data.map { |p| [ p[:name], p[:value] ] }]

      headers['ACCEPT'] = produces.join(';') if produces.present?
      headers['CONTENT_TYPE'] = consumes.join(';') if consumes.present?

      return headers
    end
  end
end
