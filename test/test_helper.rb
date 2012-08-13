require 'simplecov'
SimpleCov.start

require 'test/unit'
require 'shoulda'
require 'mocha'
require 'turn'
require 'debugger'
require 'fakeweb'


module Zaypay
  class PriceSetting
    class Rails
      def self.root
        'anywhere'
      end
    end
  end
end