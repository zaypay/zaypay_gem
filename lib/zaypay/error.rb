module Zaypay
  class Error < StandardError
     def initialize(type = nil, message = "default message")
       @type = type
       super(message)
     end
    attr_accessor :type
  end
  
end