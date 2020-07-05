# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.swagger_root = Rails.root.join('swagger').to_s

  config.swagger_dry_run = false

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.yaml'
  config.swagger_docs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      paths: {},
      servers: [
        {
          url: 'http://{defaultHost}',
          variables: {
            defaultHost: {
              default: 'localhost:3000'
            }
          }
        }
      ],
      definitions: {
        errors_object: {
          type: 'object',
          properties: {
            errors: { '$ref' => '#/definitions/errors_map' }
          }
        },
        errors_map: {
          type: 'object',
          additionalProperties: {
            type: 'array',
            items: { type: 'string' }
          }
        },
        blog: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            title: { type: 'string' },
            content: { type: 'string', 'x-nullable': true },
            thumbnail: { type: 'string', 'x-nullable': true}
          },
          required: [ 'id', 'title' ]
        },
        flexible_blog: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            headline: { type: 'string' },
            text: { type: 'string', nullable: true },
            thumbnail: { type: 'string', nullable: true }
          },
          required: ['id', 'headline']
        }
      },
      components: {
        securitySchemes: {
          basic_auth: {
            type: :basic
          },
          api_key: {
            type: :apiKey,
            name: 'api_key',
            in: :query
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The swagger_docs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.swagger_format = :yaml
end
