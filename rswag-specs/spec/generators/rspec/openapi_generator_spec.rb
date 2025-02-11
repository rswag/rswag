# frozen_string_literal: true

require 'generator_spec'
require 'generators/rspec/openapi_generator'
require 'tmpdir'

module Rspec
  describe OpenapiGenerator do
    include GeneratorSpec::TestCase
    destination Dir.mktmpdir

    before(:all) do # rubocop:disable RSpec/BeforeAfterAll # single-time setup for necessary files
      prepare_destination
      fixtures_dir = File.expand_path('fixtures', __dir__)
      FileUtils.cp_r("#{fixtures_dir}/spec", destination_root)
    end

    it 'installs the openapi_helper for rspec' do
      allow_any_instance_of(Rswag::RouteParser).to receive(:routes).and_return(fake_routes)
      run_generator ['Posts::CommentsController']

      assert_file('spec/requests/posts/comments_spec.rb') do |content|
        assert_match(/parameter name: 'post_id', in: :path, type: :string/, content)
        assert_match(/patch\('update_comments comment'\)/, content)
      end
    end

    it 'generates spec file for a controller in a defined directory' do
      allow_any_instance_of(Rswag::RouteParser).to receive(:routes).and_return(fake_routes)
      run_generator %w[Posts::CommentsController --spec_path=integration]

      assert_file('spec/integration/posts/comments_spec.rb') do |content|
        assert_match(/parameter name: 'post_id', in: :path, type: :string/, content)
        assert_match(/patch\('update_comments comment'\)/, content)
      end
    end

    private

    def fake_routes
      {
        '/posts/{post_id}/comments/{id}' => {
          params: %w[post_id id],
          actions: {
            'get' => { summary: 'show comment' },
            'patch' => { summary: 'update_comments comment' }
          }
        }
      }
    end
  end
end
