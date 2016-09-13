require 'swagger_rails/rspec/dsl'

RSpec.describe ::SwaggerRails::RSpec::DSL do
  let(:mock_class) do
    Class.new do
      include ::SwaggerRails::RSpec::DSL

      attr_reader :metadata

      def initialize
        @metadata = {}
      end
    end
  end

  subject { mock_class.new }

  describe "#parameter" do
    it "sets required: true for path parameters" do
      subject.metadata[:parameters] = []

      subject.parameter(:param_name, in: :path, type: :string)

      expect(subject.metadata[:parameters].count).to eq(1)
      expect(subject.metadata[:parameters].first).to eq({name: "param_name", in: :path, type: :string, required: true})
    end
  end
end
