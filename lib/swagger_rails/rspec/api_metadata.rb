module SwaggerRails::RSpec
  class APIMetadata

    def initialize metadata
      @metadata = metadata
    end

    def response_example?
      @metadata.has_key?(:response_code)
    end

    def swagger_doc
      @metadata[:swagger_doc]
    end

    def swagger_data
      {
        paths: {
          @metadata[:path_template] => {
            @metadata[:http_verb] => operation_metadata
          }
        }
      }
    end

    private


    def operation_metadata
      {
        tags: [find_root_of(@metadata)[:description]],
        summary: @metadata[:summary],
        description: @metadata[:implementation_notes],
        consumes: @metadata[:consumes],
        produces: @metadata[:produces],
        parameters: @metadata[:parameters],
        responses: { @metadata[:response_code] => @metadata[:response] }
      }
    end

    def find_root_of(node)
      parent = node[:parent_example_group]
      parent.nil? ? node : find_root_of(parent)
    end
  end
end