require 'active_support/core_ext/hash/slice'
require 'json'

module Rswag
  module Specs
    class RequestFactory

      def initialize(config = ::Rswag::Specs.config)
        @config = config
      end

      def build_request(metadata, example)
        swagger_doc = @config.get_swagger_doc(metadata[:swagger_doc])
        parameters = expand_parameters(metadata, swagger_doc, example)

        {}.tap do |request|
          add_verb(request, metadata)
          add_path(request, metadata, swagger_doc, parameters, example)
          add_headers(request, parameters, example)
          add_content(request, metadata, swagger_doc, parameters, example)
        end
      end

      private

      def expand_parameters(metadata, swagger_doc, example)
        operation_params = metadata[:operation][:parameters] || []
        path_item_params = metadata[:path_item][:parameters] || []
        security_params = derive_security_params(metadata, swagger_doc)

        operation_params
          .concat(path_item_params)
          .concat(security_params)
          .map { |p| p['$ref'] ? resolve_parameter(p['$ref'], swagger_doc) : p }
          .uniq { |p| "#{p[:name]}_#{p[:in]}" }
          .reject { |p| p[:required] == false && !example.respond_to?(p[:name]) }
      end

      def derive_security_params(metadata, swagger_doc)
        requirements = metadata[:operation][:security] || swagger_doc[:security]
        scheme_names = requirements ? requirements.map { |r| r.keys.first } : []
        applicable_schemes = (swagger_doc[:securityDefinitions] || {}).slice(*scheme_names).values

        applicable_schemes.map do |scheme|
          param = (scheme[:type] == :apiKey) ? scheme.slice(:name, :in) : { name: 'Authorization', in: :header }
          param.merge(type: :string)
        end
      end

      def resolve_parameter(ref, swagger_doc)
        definitions = swagger_doc[:parameters]
        key = ref.sub('#/parameters/', '')
        raise "Referenced parameter '#{ref}' must be defined" unless definitions && definitions[key]
        definitions[key]
      end

      def add_verb(request, metadata) 
        request[:verb] = metadata[:operation][:verb]
      end

      def add_path(request, metadata, swagger_doc, parameters, example)
        template = (swagger_doc[:basePath] || '') + metadata[:path_item][:template]

        request[:path] = template.tap do |template|
          parameters.select { |p| p[:in] == :path }.each do |p|
            template.gsub!("{#{p[:name]}}", example.send(p[:name]).to_s)
          end

          parameters.select { |p| p[:in] == :query }.each_with_index do |p, i|
            template.concat(i == 0 ? '?' : '&')
            template.concat(build_query_string_part(p, example.send(p[:name])))
          end
        end
      end

      def build_query_string_part(param, value)
        name = param[:name]
        return "#{name}=#{value.to_s}" unless param[:type].to_sym == :array

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

      def add_headers(request, parameters, example)
        name_value_pairs = parameters
          .select { |p| p[:in] == :header }
          .map { |p| [ p[:name], example.send(p[:name]).to_s ] }

        request[:headers] = Hash[ name_value_pairs ]
      end

      def add_content(request, metadata, swagger_doc, parameters, example)
        # Accept header
        produces = metadata[:operation][:produces] || swagger_doc[:produces]
        if produces
          accept = example.respond_to?(:'Accept') ? example.send(:'Accept') : produces.first
          request[:headers]['Accept'] = accept
        end

        # Content-Type and body
        consumes = metadata[:operation][:consumes] || swagger_doc[:consumes] 
        return if consumes.nil?

        content_type = example.respond_to?(:'Content-Type') ? example.send(:'Content-Type') : consumes.first
        request[:headers]['Content-Type'] = content_type

        if content_type.include?('json')
          body_param = parameters.select { |p| p[:in] == :body }.first
          return if body_param.nil?
          request[:body] = example.send(body_param[:name]).to_json
        end
      end
    end
  end
end
