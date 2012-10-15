module Zaypay
  # Errors that can be raised by the Zaypay gem
  class Error < StandardError
     def initialize(type = nil, message = "Error thrown by the Zaypay gem.")
       @type = type
       super(message)
     end
    attr_accessor :type
  end
  
end