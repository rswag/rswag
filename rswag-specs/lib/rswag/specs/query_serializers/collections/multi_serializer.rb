# frozen_string_literal: true

module Rswag
  module Specs
    module QuerySerializers
      module Collections
        class MultiSerializer
          def serialize(name, value)
            value.map { |v| "#{CGI.escape(name.to_s)}=#{CGI.escape(v.to_s)}" }.join("&")
          end
        end
      end
    end
  end
end
