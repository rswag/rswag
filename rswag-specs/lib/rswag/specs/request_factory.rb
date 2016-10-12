require 'active_support/core_ext/hash/slice'
require 'json'

module Rswag
  module Specs
    class RequestFactory

      def initialize(api_metadata, global_metadata)
        @api_metadata = api_metadata
        @global_metadata = global_metadata
      end

      def build_fullpath(example)
        @api_metadata[:path].dup.tap do |t|
          parameters_in(:path).each { |p| t.gsub!("{#{p[:name]}}", example.send(p[:name]).to_s) }
          t.concat(build_query(example))
          t.prepend(@global_metadata[:basePath] || '')
        end
      end

      def build_query(example)
        query_string = parameters_in(:query)
          .map { |p| "#{p[:name]}=#{example.send(p[:name])}" }
          .join('&')

        query_string.empty? ? '' : "?#{query_string}"
      end

      def build_body(example)
        body_parameter = parameters_in(:body).first
        body_parameter.nil? ? '' : example.send(body_parameter[:name]).to_json
      end

      def build_headers(example)
        headers = Hash[ parameters_in(:header).map { |p| [ p[:name], example.send(p[:name]).to_s ] } ]
        headers.tap do |h|
          produces = @api_metadata[:operation][:produces] || @global_metadata[:produces]
          consumes = @api_metadata[:operation][:consumes] || @global_metadata[:consumes]
          h['ACCEPT'] = produces.join(';') unless produces.nil?
          h['CONTENT_TYPE'] = consumes.join(';') unless consumes.nil?
        end
      end

      private

      def parameters_in(location)
        (@api_metadata[:operation][:parameters] || [])
          .map { |p| p['$ref'] ? resolve_parameter(p['$ref']) : p } # resolve any references
          .concat(resolve_api_key_parameters)
          .select { |p| p[:in] == location }
      end

      def resolve_parameter(ref)
        defined_params = @global_metadata[:parameters] 
        key = ref.sub('#/parameters/', '')
        raise "Referenced parameter '#{ref}' must be defined" unless defined_params && defined_params[key]
        defined_params[key]
      end

      def resolve_api_key_parameters
        @api_key_params ||= begin
          global_requirements = (@global_metadata[:security] || {})
          requirements = global_requirements.merge(@api_metadata[:operation][:security] || {})
          definitions = (@global_metadata[:securityDefinitions] || {}).slice(*requirements.keys)
          definitions.values.select { |d| d[:type] == :apiKey }
        end
      end
    end
  end
end
