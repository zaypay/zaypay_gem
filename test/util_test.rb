require 'test_helper'
require 'zaypay'

class UtilTest < Test::Unit::TestCase
  context "Zaypay::Util" do
    context "uber_symbolize" do
      should "have all keys of nested hashes symbolized" do
        result = Zaypay::Util.uber_symbolize({'a' => 'a', 
                                              :b => 'b', 
                                              :hash => {'country' => 'Germany', 'code' => 'DE'}, 
                                              :array => ['key' => 'ak', 'val' => 'av'],
                                              :nested_hash => {'nested_hash' => {'response' => {'status' => 'ok'}}},
                                              'nested_array' => [ {'a' => 'a'}, 
                                                                  [ {'nested_array' => 'value'}, ['innerinner' => 'innerinnervalue']]
                                                                ],
                                              1 => '1'})

        assert_equal ({:a => 'a',
                      :b => 'b', 
                      :hash => {:country => 'Germany', :code => 'DE'},
                      :array => [:key => 'ak', :val => 'av'],
                      :nested_hash => {:nested_hash => {:response => {:status => 'ok'}}},
                      :nested_array => [ 
                                         {:a => 'a'},
                                         [ 
                                           {:nested_array => 'value'},
                                           [:innerinner => 'innerinnervalue']
                                         ]
                                       ],
                      1 => '1'}), result
      end
    end

    context "stringify_locale_hash" do
      should "return a correct string" do
        locale_string = Zaypay::Util.stringify_locale_hash({:language=>"nl", :country=>"NL"})
        assert_equal 'nl-NL', locale_string
      end
    end
  
    context "arrayify_if_not_an_array" do
      should "wrap any object into an array" do
        assert_equal ["foobar"], Zaypay::Util.arrayify_if_not_an_array("foobar")
        assert_equal ["foobar"], Zaypay::Util.arrayify_if_not_an_array(["foobar"])
      end
    end
  end
end