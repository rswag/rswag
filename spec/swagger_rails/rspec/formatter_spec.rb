require 'swagger_rails/rspec/formatter'
require 'swagger_rails/rspec/dsl'
require 'rails_helper'

RSpec.describe ::SwaggerRails::RSpec::Formatter do
  include FormatterSupport

  def group
    RSpec.describe('Ping API', swagger_doc: 'v1_api.json') do
      path('/ping') do
        post('checks if site is alive') do
          consumes('application/json')
          produces('application/json')
          operation_description('A very long description')
          response('200', '(OK) Site up and running') do
            run_test!
          end
        end
      end
    end
  end

  def send_notification_for_all_child_groups(group)
    send_notification :example_group_finished, group_notification(group)
    group.children.each do |child|
      return if child.class.name == 'ValidRequest'
      send_notification_for_all_child_groups(child)
    end
  end

  def swaggerize(*groups)
    groups.each do |group|
      group.run(reporter)
      send_notification_for_all_child_groups group
    end
  end

  before(:each) do
    swagger_root = (Rails.root + 'swagger').to_s
    SwaggerRails::Configuration.new.tap { |c| c.swagger_root = swagger_root }
    allow(RSpec.configuration).to receive(:swagger_docs).and_return({ 'v1_api.json' => { swagger: '2.0',
                                                                                         info: { title: 'API V1',
                                                                                                 version: 'v1' } } })
    allow(RSpec.configuration).to receive(:swagger_root).and_return(swagger_root)
    @formatter = SwaggerRails::RSpec::Formatter.new(StringIO.new)
  end

  describe '#new' do
    it 'should initialize the swagger_root' do
      expect(@formatter.instance_variable_get(:@swagger_root)).to eq((Rails.root + 'swagger').to_s)
      expect(@formatter.instance_variable_get(:@swagger_docs)).to eq({"v1_api.json"=>{:swagger=>"2.0", :info=>{:title=>"API V1", :version=>"v1"}}})
    end
  end

  describe '#example_group_finished' do
    before do
      swaggerize(group)
    end

    it "should print 'Generating Swagger Docs ...'" do
      expect(formatter_output.string).to eq("Generating Swagger Docs ...\n")
    end

    it 'should update the swagger_doc instance variable' do
      expect(@formatter.instance_variable_get(:@swagger_docs)
      ).to eq({
                'v1_api.json' => { :swagger => '2.0',
                                   :info => { :title => 'API V1',
                                              :version => 'v1' },
                                   :paths => { '/ping' => { :post => { :tags => ['Ping API'],
                                                                        :summary => 'checks if site is alive',
                                                                        :description => 'A very long description',
                                                                        :consumes => ['application/json'],
                                                                        :produces => ['application/json'],
                                                                        :parameters => [],
                                                                        :responses => { '200' => { :description => '(OK) Site up and running' } } } } } } })
    end
  end
end
