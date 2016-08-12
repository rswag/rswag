require 'swagger_rails/rspec/api_metadata'
require 'rails_helper'

RSpec.describe ::SwaggerRails::RSpec::APIMetadata do

  let(:operation_metadata) { { :execution_result => '#<RSpec::Core::Example::ExecutionResult>',
                               :block => '#<Proc>',
                               :description_args => ['(OK) Site up and running'],
                               :description => '(OK) Site up and running',
                               :full_description => 'Ping API /ping post (OK) Site up and running',
                               :described_class => :post,
                               :file_path => './spec/swagger_rails/rspec/formatter_spec.rb',
                               :line_number => 15,
                               :location => './spec/swagger_rails/rspec/formatter_spec.rb:15',
                               :absolute_file_path => '/Users/someuser/work/swagger_rails/spec/swagger_rails/rspec/formatter_spec.rb',
                               :rerun_file_path => './spec/swagger_rails/rspec/formatter_spec.rb',
                               :scoped_id => '4:1:1:1',
                               :swagger_doc => 'v1_api.json' } }

  let(:response_metadata) { { :execution_result => '#<RSpec::Core::Example::ExecutionResult>',
                              :block => '#<Proc>',
                              :description_args => ['(OK) Site up and running'],
                              :description => '(OK) Site up and running',
                              :full_description => 'Ping API /ping post (OK) Site up and running',
                              :described_class => :post,
                              :file_path => './spec/swagger_rails/rspec/formatter_spec.rb',
                              :line_number => 15,
                              :location => './spec/swagger_rails/rspec/formatter_spec.rb:15',
                              :absolute_file_path => '/Users/someuser/work/swagger_rails/spec/swagger_rails/rspec/formatter_spec.rb',
                              :rerun_file_path => './spec/swagger_rails/rspec/formatter_spec.rb',
                              :scoped_id => '4:1:1:1',
                              :swagger_doc => 'v1_api.json',
                              :parent_example_group => {
                                :execution_result => '#<RSpec::Core::Example::ExecutionResult>',
                                :block => '#<Proc>',
                                :description_args => [:post],
                                :description => 'post',
                                :full_description => 'Ping API /ping post',
                                :described_class => :post,
                                :file_path => './spec/swagger_rails/rspec/formatter_spec.rb',
                                :line_number => 11,
                                :location => './spec/swagger_rails/rspec/formatter_spec.rb:11',
                                :absolute_file_path => '/Users/someuser/work/swagger_rails/spec/swagger_rails/rspec/formatter_spec.rb',
                                :rerun_file_path => './spec/swagger_rails/rspec/formatter_spec.rb',
                                :scoped_id => '4:1:1',
                                :swagger_doc => 'v1_api.json',
                                :parent_example_group => {
                                  :execution_result => '#<RSpec::Core::Example::ExecutionResult>',
                                  :block => '#<Proc>',
                                  :description_args => ['/ping'],
                                  :description => '/ping',
                                  :full_description => 'Ping API /ping',
                                  :described_class => nil,
                                  :file_path => './spec/swagger_rails/rspec/formatter_spec.rb',
                                  :line_number => 10,
                                  :location => './spec/swagger_rails/rspec/formatter_spec.rb:10',
                                  :absolute_file_path => '/Users/someuser/work/swagger_rails/spec/swagger_rails/rspec/formatter_spec.rb',
                                  :rerun_file_path => './spec/swagger_rails/rspec/formatter_spec.rb',
                                  :scoped_id => '4:1',
                                  :swagger_doc => 'v1_api.json',
                                  :parent_example_group => {
                                    :execution_result => '#<RSpec::Core::Example::ExecutionResult>',
                                    :block => '#<Proc>',
                                    :description_args => ['Ping API'],
                                    :description => 'Ping API',
                                    :full_description => 'Ping API',
                                    :described_class => nil,
                                    :file_path => './spec/swagger_rails/rspec/formatter_spec.rb',
                                    :line_number => 9,
                                    :location => './spec/swagger_rails/rspec/formatter_spec.rb:9',
                                    :absolute_file_path => '/Users/someuser/work/swagger_rails/spec/swagger_rails/rspec/formatter_spec.rb',
                                    :rerun_file_path => './spec/swagger_rails/rspec/formatter_spec.rb',
                                    :scoped_id => '4',
                                    :swagger_doc => 'v1_api.json' },
                                  :path_template => '/ping' },
                                :path_template => '/ping',
                                :http_verb => :post,
                                :summary => 'checks if site is alive',
                                :parameters => [],
                                :consumes => ['application/json'],
                                :produces => ['application/json'],
                                :operation_description => 'A very long description' },
                              :path_template => '/ping',
                              :http_verb => :post,
                              :summary => 'checks if site is alive',
                              :parameters => [],
                              :consumes => ['application/json'],
                              :produces => ['application/json'],
                              :operation_description => 'A very long description',
                              :response_code => '200',
                              :response => { :description => '(OK) Site up and running' } }
  }

  describe '#response_example?' do
    it 'should return false if response_code not found' do
      request_metadata = SwaggerRails::RSpec::APIMetadata.new(operation_metadata)
      expect(request_metadata).to_not be_response_example
    end

    it 'should return true if response_code found' do
      request_metadata = SwaggerRails::RSpec::APIMetadata.new(response_metadata)
      expect(request_metadata).to be_response_example
    end
  end

  describe '#swagger_doc' do
    it 'should return the swagger_doc in the metadata' do
      request_metadata = SwaggerRails::RSpec::APIMetadata.new(response_metadata)
      expect(request_metadata.swagger_doc).to eq('v1_api.json')
    end
  end

  describe '#swagger_data' do
    it 'should return swagger specific metadata' do
      request_metadata = SwaggerRails::RSpec::APIMetadata.new(response_metadata)
      expect(request_metadata.swagger_data).to eq({ :paths => { '/ping' => { :post => { :tags => ['Ping API'],
                                                                                        :summary => 'checks if site is alive',
                                                                                        :description => 'A very long description',
                                                                                        :consumes => ['application/json'],
                                                                                        :produces => ['application/json'],
                                                                                        :parameters => [],
                                                                                        :responses => { '200' => { :description => '(OK) Site up and running' } } } } } })
    end
  end
end