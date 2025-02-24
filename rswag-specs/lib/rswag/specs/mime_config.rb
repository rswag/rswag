module Rswag
  module Specs
    class MimeConfig
      def initialize(endpoint, mime, parameter)
        @endpoint = endpoint
        @mime = mime
        @parameter = parameter
        @endpoint[:requestBody][:content][mime] ||= {}
        @mime_config = endpoint[:requestBody][:content][mime]
      end

      def schema? = @mime_config[:schema].present?
      def properties? = !!@mime_config[:schema][:properties]

      def prepare
        # Only parse parameters if there has not already been a reference object set. Ie if a `in: :body` parameter
        # has been seen already `schema` is defined, or if formData is being used then ensure we have a `properties`
        # key in schema.
        return unless !schema? || properties?

        set_mime_config
        set_mime_examples
        set_request_body_required
      end

      def set_request_body_required
        return unless @parameter[:required]

        # FIXME: If any are `required` then the body is set to `required` but this assumption may not hold in reality as
        # you could have optional body, but if body is provided then some properties are required.
        # TODO: Try to move the following line out of this class so
        # so that we can stop mutating the @endpoint object
        @endpoint[:requestBody][:required] = true

        return if @parameter[:in] == :body

        if @parameter[:name]
          @mime_config[:schema][:required] ||= []
          @mime_config[:schema][:required] << @parameter[:name].to_s
        else
          @mime_config[:schema][:required] = true
        end
      end

      def set_mime_examples
        @endpoint[:request_examples]&.each do |example|
          @mime_config[:examples] ||= {}
          @mime_config[:examples][example[:name]] = {
            summary: example[:summary] || @endpoint[:summary],
            value: example[:value]
          }
        end
      end

      def set_mime_config
        schema_with_form_properties = @parameter[:name] && @parameter[:in] != :body
        @mime_config[:schema] ||= schema_with_form_properties ? { type: :object, properties: {} } : @parameter[:schema]
        return unless schema_with_form_properties

        @mime_config[:schema][:properties][@parameter[:name]] = @parameter[:schema]
        set_mime_encoding
      end

      def set_mime_encoding
        encoding = @parameter[:encoding].dup || return
        encoding[:contentType] = encoding[:contentType].join(',') if encoding[:contentType].is_a?(Array)
        @mime_config[:encoding] ||= {}
        @mime_config[:encoding][@parameter[:name]] = encoding
      end
    end
  end
end
