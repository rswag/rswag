# frozen_string_literal: true

RSpec.describe Rswag::RouteParser do
  describe "#routes" do
    let(:controller) { "api/v1/posts" }
    subject { described_class.new(controller) }

    let(:routes) do
      [
        double(
          defaults: {
            controller: controller
          },
          path: double(
            spec: double(
              to_s: "/api/v1/posts/:id(.:format)"
            )
          ),
          verb: "GET",
          requirements: {
            action: "show",
            controller: "api/v1/posts"
          },
          segments: ["id", "format"]
        )  
      ]
    end

    let(:expectation) do
      {
        "/api/v1/posts/{id}" => { 
          params: ["id"],
          actions: {
            "get" => {
              summary: "show post"
            }
          }
        }
      }
    end

    before do
      allow(::Rails).to receive_message_chain("application.routes.routes") { routes }
    end

    it "returns correct routes" do
      expect(subject.routes).to eq(expectation)
    end
  end
end
