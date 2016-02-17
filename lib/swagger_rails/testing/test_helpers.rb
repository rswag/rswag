require 'swagger_rails/testing/test_visitor'

module SwaggerRails
  module TestHelpers

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      attr_reader :test_visitor

      def swagger_doc(swagger_doc)
        file_path = File.join(Rails.root, 'config/swagger', swagger_doc)
        @swagger = JSON.parse(File.read(file_path))
        @test_visitor = SwaggerRails::TestVisitor.new(@swagger)
      end

      def swagger_test_all
        @swagger['paths'].each do |path, path_item| 
          path_item.keys.each do |method| 
            test "#{path} #{method}" do
              swagger_test path, method
            end
          end
        end
      end
    end

    def swagger_test(path, method)
      self.class.test_visitor.run_test(path, method, self)
    end
  end
end
