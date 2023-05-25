# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.swagger_root = Rails.root.to_s + '/swagger'
  config.swagger_dry_run = false
  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:to_swagger' rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.swagger_docs = {
    'v1/swagger.json' => {
      openapi: '3.0.0',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      paths: {},
      servers: [
        {
          url: '{protocol}://{defaultHost}',
          variables: {
            protocol: {
              default: :https
            },
            defaultHost: {
              default: 'www.example.com'
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
            type: :http,
            scheme: :basic
          },
          api_key: {
            type: :apiKey,
            name: 'api_key',
            in: :query
          }
        }
      }
    },
    'v3/openapi.json' => {
      openapi: '3.0.0',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      paths: {},
      servers: [
        {
          url: 'https://{defaultHost}',
          variables: {
            defaultHost: {
              default: 'www.example.com'
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
            type: :http,
            scheme: :basic
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
end
