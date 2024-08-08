# frozen_string_literal: true

module Rswag
  module Specs
    module QuerySerializers
      class PrimitiveSerializer
        def serialize(name, value)
          "#{CGI.escape(name.to_s)}=#{CGI.escape(value.to_s)}"
        end
      end
    end
  end
end
