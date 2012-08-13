# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "zaypay/version"

Gem::Specification.new do |s|
  s.name        = "zaypay"
  s.version     = Zaypay::VERSION
  s.authors     = ["Zaypay"]
  s.email       = ["alex@zaypay.com"]
  s.homepage    = "http://www.github.com/zaypay"
  s.summary     = %q{Wrapper for the ZayPay API}
  s.description = %q{This gem provides you a PriceSetting class which allows you to send request to the Zaypay API in order to create payments, display payment details and contains other useful methods. Pleases refer to http://zaypay.com/developers for more information on the Zaypay API}

  s.files         = ['lib/zaypay.rb', 'lib/zaypay/error.rb', 'lib/zaypay/price_setting.rb', 'lib/zaypay/util.rb', 'lib/zaypay/version.rb']
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('httparty', '~> 0.8.1')
  s.add_development_dependency('debugger')
  s.add_development_dependency('mocha')
  s.add_development_dependency('shoulda')
  s.add_development_dependency('fakeweb')
  s.add_development_dependency('minitest')
  s.add_development_dependency('simplecov')
  s.add_development_dependency('turn')
  s.add_development_dependency('test-unit', '~> 2.0.0')
end
