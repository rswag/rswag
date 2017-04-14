require 'rswag/specs/request_factory'

module Rswag
  module Specs

    describe RequestFactory do
      subject { RequestFactory.new(api_metadata, global_metadata) }

      before do
        allow(example).to receive(:blog_id).and_return(1)
        allow(example).to receive(:id).and_return('2')
      end
      let(:api_metadata) do
        {
          path_item: { template: '/blogs/{blog_id}/comments/{id}' },
          operation: {
            verb: :put,
            summary: 'Updates a blog',
            parameters: [
              { name: :blog_id, in: :path, type: 'integer' },
              { name: 'id', in: :path, type: 'integer' }
            ]
          }
        }
      end
      let(:global_metadata) { {} }
      let(:example) { double('example') }

      describe '#build_fullpath(example)' do
        let(:path) { subject.build_fullpath(example) }

        context 'always' do
          it "builds a path using metadata and example values" do
            expect(path).to eq('/blogs/1/comments/2')
          end
        end

        context "'query' parameters" do
          before do
            api_metadata[:operation][:parameters] << { name: 'q1', in: :query, type: 'string' }
            api_metadata[:operation][:parameters] << { name: 'q2', in: :query, type: 'string' }
            allow(example).to receive(:q1).and_return('foo')
            allow(example).to receive(:q2).and_return('bar')
          end

          it "appends a query string using metadata and example values" do
            expect(path).to eq('/blogs/1/comments/2?q1=foo&q2=bar')
          end
        end

        context "'query' parameter of type 'array'" do
          before do
            api_metadata[:operation][:parameters] << {
              name: 'things',
              in: :query,
              type: :array,
              collectionFormat: collectionFormat
            }
            allow(example).to receive(:things).and_return([ 'foo', 'bar' ])
          end

          context 'collectionFormat = csv' do
            let(:collectionFormat) { :csv }
            it "formats as comma separated values" do
              expect(path).to eq('/blogs/1/comments/2?things=foo,bar')
            end
          end

          context 'collectionFormat = ssv' do
            let(:collectionFormat) { :ssv }
            it "formats as space separated values" do
              expect(path).to eq('/blogs/1/comments/2?things=foo bar')
            end
          end

          context 'collectionFormat = tsv' do
            let(:collectionFormat) { :tsv }
            it "formats as tab separated values" do
              expect(path).to eq('/blogs/1/comments/2?things=foo\tbar')
            end
          end

          context 'collectionFormat = pipes' do
            let(:collectionFormat) { :pipes }
            it "formats as pipe separated values" do
              expect(path).to eq('/blogs/1/comments/2?things=foo|bar')
            end
          end

          context 'collectionFormat = multi' do
            let(:collectionFormat) { :multi }
            it "formats as multiple parameter instances" do
              expect(path).to eq('/blogs/1/comments/2?things=foo&things=bar')
            end
          end
        end

        context "global definition for 'api_key in query'" do
          before do
            global_metadata[:securityDefinitions] = { api_key: { type: :apiKey, name: 'api_key', in: :query } }
            allow(example).to receive(:api_key).and_return('fookey')
          end

          context 'global requirement' do
            before { global_metadata[:security] = [ { api_key: [] } ] }

            it "appends the api_key using metadata and example value" do
              expect(path).to eq('/blogs/1/comments/2?api_key=fookey')
            end
          end

          context 'operation-specific requirement' do
            before { api_metadata[:operation][:security] = [ { api_key: [] } ] }

            it "appends the api_key using metadata and example value" do
              expect(path).to eq('/blogs/1/comments/2?api_key=fookey')
            end
          end
        end

        context 'global basePath' do
          before { global_metadata[:basePath] = '/foobar' }

          it 'prepends the basePath' do
            expect(path).to eq('/foobar/blogs/1/comments/2')
          end
        end

        context "defined at the 'path' level" do
          before do
            api_metadata[:path_item][:parameters] = [ { name: :blog_id, in: :path } ]
            api_metadata[:operation][:parameters] = [ { name: :id, in: :path } ]
          end

          it "builds path from parameters defined at path and operation levels" do
            expect(path).to eq('/blogs/1/comments/2')
          end
        end
      end

      describe '#build_body(example)' do
        let(:body) { subject.build_body(example) }

        context "no 'body' parameter" do
          it "returns ''" do
            expect(body).to eq('')
          end
        end

        context "'body' parameter" do
          before do
            api_metadata[:operation][:parameters] << { name: 'comment', in: :body, schema: { type: 'object' } }
            allow(example).to receive(:comment).and_return(text: 'Some comment')
          end

          it 'returns the example value as a json string' do
            expect(body).to eq("{\"text\":\"Some comment\"}")
          end
        end

        context "'formData' parameter" do
          before do
            api_metadata[:operation][:parameters] << { name: 'comment', in: :formData, type: 'string' }
            allow(example).to receive(:comment).and_return('Some comment')
          end

          it 'returns the example value as a hash' do
            expect(body).to eq({"comment" => "Some comment"})
          end
        end

        context "referenced 'body' parameter" do
          before do
            api_metadata[:operation][:parameters] << { '$ref' => '#/parameters/comment' }
            global_metadata[:parameters] = {
              'comment' => { name: 'comment', in: :body, schema: { type: 'object' } }
            }
            allow(example).to receive(:comment).and_return(text: 'Some comment')
          end

          it 'returns the example value as a json string' do
            expect(body).to eq("{\"text\":\"Some comment\"}")
          end
        end

        context "referenced 'formData' parameter" do
          before do
            api_metadata[:operation][:parameters] << { '$ref' => '#/parameters/comment' }
            global_metadata[:parameters] = {
              'comment' => { name: 'comment', in: :formData, type: 'string' }
            }
            allow(example).to receive(:comment).and_return('Some comment')
          end

          it 'returns the example value as a json string' do
            expect(body).to eq({"comment" => "Some comment"})
          end
        end
      end

      describe '#build_headers' do
        let(:headers) { subject.build_headers(example) }

        context "no 'header' params" do
          it 'returns an empty hash' do
            expect(headers).to eq({})
          end
        end

        context "'header' params" do
          before do
            api_metadata[:operation][:parameters] << { name: 'Api-Key', in: :header, type: 'string' }
            allow(example).to receive(:'Api-Key').and_return('foobar')
          end

          it 'returns a hash of names with example values' do
            expect(headers).to eq({ 'Api-Key' => 'foobar' })
          end
        end

        context 'consumes & produces' do
          before do
            api_metadata[:operation][:consumes] =  [ 'application/json', 'application/xml' ]
            api_metadata[:operation][:produces] =  [ 'application/json', 'application/xml' ]
          end

          it "includes corresponding 'Accept' & 'Content-Type' headers" do
            expect(headers).to match(
              'ACCEPT' => 'application/json;application/xml',
              'CONTENT_TYPE' => 'application/json;application/xml'
            )
          end
        end

        context 'global consumes & produces' do
          let(:global_metadata) do
            {
              consumes: [ 'application/json', 'application/xml' ],
              produces: [ 'application/json', 'application/xml' ]
            }
          end

          it "includes corresponding 'Accept' & 'Content-Type' headers" do
            expect(headers).to match(
              'ACCEPT' => 'application/json;application/xml',
              'CONTENT_TYPE' => 'application/json;application/xml'
            )
          end
        end
      end
    end
  end
end
