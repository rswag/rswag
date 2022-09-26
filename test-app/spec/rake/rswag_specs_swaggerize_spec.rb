# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.describe 'rswag:specs:swaggerize' do
  let(:swagger_root) { Rails.root.to_s + '/swagger' }
  before do
    TestApp::Application.load_tasks
    FileUtils.rm_r(swagger_root) if File.exist?(swagger_root)
  end

  it 'generates Swagger JSON files from integration specs' do
    Rake::Task['rswag:specs:swaggerize'].invoke
    expect(File).to exist("#{swagger_root}/v1/swagger.json")
  end
end
