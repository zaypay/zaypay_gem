require 'simplecov'
SimpleCov.start

require 'test/unit'
require 'shoulda'
require 'rr'
require 'turn'

require 'active_support'
require 'active_support/core_ext/hash'

module Zaypay
  class PriceSetting
    class Rails
      def self.root
        'anywhere'
      end
    end
  end
end