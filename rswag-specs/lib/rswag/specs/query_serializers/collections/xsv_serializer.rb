# frozen_string_literal: true

module Rswag
  module Specs
    module QuerySerializers
      module Collections
        class XSVSerializer
          def initialize(sep)
            @sep = sep
          end

          def serialize(name, value)
            "#{CGI.escape(name.to_s)}=#{value.map { |v| CGI.escape(v.to_s) }.join(@sep)}"
          end
        end
      end
    end
  end
end
