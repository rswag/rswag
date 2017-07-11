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
        @api_metadata[:path_item][:template].dup.tap do |t|
          t.prepend(@global_metadata[:basePath] || '')
          parameters_in(:path).each { |p| t.gsub!("{#{p[:name]}}", example.send(p[:name]).to_s) }
          t.concat(build_query_string(example))
        end
      end

      def build_query_string(example)
        query_string = parameters_in(:query)
          .select { |p| p.fetch(:required, true) ||
                        example.respond_to?(p[:name]) }
          .map { |p| build_query_string_part(p, example.send(p[:name])) }
          .join('&')

        query_string.empty? ? '' : "?#{query_string}"
      end

      def build_body(example)
        body_parameter = parameters_in(:body).first
        body_parameter.nil? ? '' : example.send(body_parameter[:name]).to_json
      end

      def build_headers(example)
        name_value_pairs = parameters_in(:header).map do |param|
          [
            param[:name],
            example.send(param[:name]).to_s
          ]
        end

        # Add MIME type headers based on produces/consumes metadata
        produces = @api_metadata[:operation][:produces] || @global_metadata[:produces]
        consumes = @api_metadata[:operation][:consumes] || @global_metadata[:consumes]
        name_value_pairs << [ 'Accept', produces.join(';') ] unless produces.nil?
        name_value_pairs << [ 'Content-Type', consumes.join(';') ] unless consumes.nil?

        Hash[ name_value_pairs ]
      end

      private

      def parameters_in(location)
        path_item_params = @api_metadata[:path_item][:parameters] || []
        operation_params = @api_metadata[:operation][:parameters] || []
        applicable_params = operation_params
          .concat(path_item_params)
          .uniq { |p| p[:name] } # operation params should override path_item params

        applicable_params
          .map { |p| p['$ref'] ? resolve_parameter(p['$ref']) : p } # resolve any references
          .concat(security_parameters)
          .select { |p| p[:in] == location }
      end

      def resolve_parameter(ref)
        defined_params = @global_metadata[:parameters]
        key = ref.sub('#/parameters/', '')
        raise "Referenced parameter '#{ref}' must be defined" unless defined_params && defined_params[key]
        defined_params[key]
      end

      def security_parameters
        applicable_security_schemes.map do |scheme|
          if scheme[:type] == :apiKey
            { name: scheme[:name], type: :string, in: scheme[:in] }
          else
            { name: 'Authorization', type: :string, in: :header } # use auth header for basic & oauth2
          end
        end
      end

      def applicable_security_schemes
        # First figure out the security requirement applicable to the operation
        requirements = @api_metadata[:operation][:security] || @global_metadata[:security]
        scheme_names = requirements ? requirements.map { |r| r.keys.first } : []

        # Then obtain the scheme definitions for those requirements
        (@global_metadata[:securityDefinitions] || {}).slice(*scheme_names).values
      end

      def build_query_string_part(param, value)
        return "#{param[:name]}=#{value.to_s}" unless param[:type].to_sym == :array

        name = param[:name]
        case param[:collectionFormat]
        when :ssv
          "#{name}=#{value.join(' ')}"
        when :tsv
          "#{name}=#{value.join('\t')}"
        when :pipes
          "#{name}=#{value.join('|')}"
        when :multi
          value.map { |v| "#{name}=#{v}" }.join('&')
        else
          "#{name}=#{value.join(',')}" # csv is default
        end
      end
    end
  end
end
