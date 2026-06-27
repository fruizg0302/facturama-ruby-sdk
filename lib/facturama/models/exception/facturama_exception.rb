
require_relative 'model_exception'


class FacturamaException < StandardError

    def initialize( exception_message, exception_details = nil  )
        super exception_message

        @details = exception_details
    end


    def details
        @details
    end

end