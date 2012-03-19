require 'test_helper'
require 'zaypay'

class ZaypayTest < Test::Unit::TestCase
  include RR::Adapters::TestUnit

  context "Zaypay::PriceSetting" do

    setup do
      @price_setting_id = 131404
      @api_key = '43b02bf0bf6c956d74a18e1e598338b0'
      @ps = Zaypay::PriceSetting.new(@price_setting_id, @api_key)
      @base_uri = 'https://secure.zaypay.com'
      @headers = {'Accept' => 'application/xml' }
      @ip = '95.97.131.28'
    end
    
    
    context "#initialize" do
      context "with no-args" do
        should "lookup for a yml within Rails config" do
          mock(YAML).load_file('anywhere/config/zaypay.yml').returns({131404=>"43b02bf0bf6c956d74a18e1e598338b0", "default"=>131404})
          Zaypay::PriceSetting.new
        end
        
        should "raise Error if the yml file is not present" do
          assert_raise Errno::ENOENT do
            mock.proxy(YAML).load_file("anywhere/config/zaypay.yml")
            Zaypay::PriceSetting.new
          end
        end
      end
    end
    
    context "#locale_for_ip" do
    
      should "call class method get" do
        mock.proxy(Zaypay::PriceSetting).get("#{@base_uri}/#{@ip}/pay/#{@ps.price_setting_id}/locale_for_ip", {:query => {:key => @api_key}, :headers => @headers })
        @ps.locale_for_ip('95.97.131.28')
      end
    
      should "return a country-language hash" do
        locale = @ps.locale_for_ip('95.97.131.28')
        assert locale.has_key?(:country)
        assert locale.has_key?(:language)
      end
    end
    
    context "#list_locales" do
      context "with optional amount" do
        should "call class method GET with the correct url" do
          mock.proxy(Zaypay::PriceSetting).get("#{@base_uri}/10/pay/#{@price_setting_id}/list_locales", {:query => {:key => @api_key}, :headers => @headers } )
          @ps.list_locales(10)
        end
      end
      
      should "call class method GET with the correct url" do
        amount = nil
        mock.proxy(Zaypay::PriceSetting).get("#{@base_uri}/#{amount}/pay/#{@price_setting_id}/list_locales", {:query => {:key => @api_key}, :headers => @headers } )
        @ps.list_locales
      end
    
      should "contain a langauages hash and a countries hash" do
        locales = @ps.list_locales
        assert locales.has_key?(:countries)
        assert locales.has_key?(:languages)
      end
    end
    
    context "#list_countries" do      
      
      context "with optional amount" do
        should "call class method GET with the correct url" do
          mock.proxy(Zaypay::PriceSetting).get("#{@base_uri}/10/pay/#{@price_setting_id}/list_locales", {:query => {:key => @api_key}, :headers => @headers } )
          @ps.list_countries(10)
        end
      end
      
      should "call class method get" do
        mock.proxy(Zaypay::PriceSetting).get("#{@base_uri}//pay/#{@price_setting_id}/list_locales", {:query => {:key => @api_key}, :headers => @headers } )
        @ps.list_countries
      end
      
      should "returns same results as #list_locales[:countries]" do
        results = @ps.list_countries
        assert_equal results, @ps.list_locales[:countries]
        assert results.kind_of?(Array)
      end
    end
    
    context "#list_languages" do
      
      context "with optional amount" do
        should "call class method GET with the correct url" do
          mock.proxy(Zaypay::PriceSetting).get("#{@base_uri}/10/pay/#{@price_setting_id}/list_locales", {:query => {:key => @api_key}, :headers => @headers } )
          @ps.list_languages(10)
        end
      end
      
      should "call class method get" do
        mock.proxy(Zaypay::PriceSetting).get("#{@base_uri}//pay/#{@price_setting_id}/list_locales", {:query => {:key => @api_key}, :headers => @headers } )
        @ps.list_languages
      end
      
      should "returns same results as #list_locales[:languages]" do
        results = @ps.list_languages
        assert_equal results, @ps.list_locales[:languages]
        assert_equal true, results.kind_of?(Array)
      end
    end
    
    context "#list_payment_methods" do
      
      context "with optional amount" do
        should "call class method GET with the correct url" do
          mock.proxy(Zaypay::PriceSetting).get("#{@base_uri}/10/nl-NL/pay/#{@price_setting_id}/payments/new", {:query => {:key => @api_key}, :headers => @headers } )
          payment_methods = @ps.list_payment_methods('nl-NL', 10)
        end
      end
      
      should "call class method get" do
        mock.proxy(Zaypay::PriceSetting).get("#{@base_uri}//nl-NL/pay/#{@price_setting_id}/payments/new", {:query => {:key => @api_key}, :headers => @headers } )
        @ps.list_payment_methods('nl-NL')
      end
      
      should "return a hash with the key 'payment_methods" do
        payment_methods = @ps.list_payment_methods('nl-NL')
        assert payment_methods.has_key?(:payment_methods)
      end
      
      context "call with a locale-hash as arg" do
        setup do
          @locale = @ps.locale_for_ip('82.94.123.123')
        end
        
        should "call #stringify_locale_hash" do
          mock.proxy(@ps).stringify_locale_hash({:country=>"NL", :language=>"nl"})
          @ps.list_payment_methods(@locale)
        end
        
        should "call class method GET with the correct URL" do
          mock.proxy(Zaypay::PriceSetting).get("#{@base_uri}/10/nl-NL/pay/#{@price_setting_id}/payments/new", {:query => {:key => @api_key}, :headers => @headers } )
          @ps.list_payment_methods(@locale, 10)
        end
      end
    end
    
    context "#create_payment" do
      
      context  "with optional amount" do
        should "call class method POST with the correct url" do
          mock.proxy(Zaypay::PriceSetting).post("#{@base_uri}/10/nl-NL/pay/#{@price_setting_id}/payments", {:query => {:key => @api_key, :payment_method_id => 2}, :headers => @headers })
          @ps.create_payment('nl-NL', 2, 10)          
        end
      end
      
      should "call class method POST" do
        mock.proxy(Zaypay::PriceSetting).post("#{@base_uri}//nl-NL/pay/#{@price_setting_id}/payments", {:query => {:key => @api_key, :payment_method_id => 2}, :headers => @headers })
        @ps.create_payment('nl-NL', 2)
      end
      
      should "return a hash with a :payment and :instructions keys" do
        payment = @ps.create_payment('nl-NL', 2)
        assert payment.has_key?(:payment)
        assert payment.has_key?(:instructions)
      end
    end
    
    context "#create_payment_with_custom_variables" do
      context "with optional amount" do
        should "call class method POST with the correct url" do
          mock.proxy(Zaypay::PriceSetting).post("#{@base_uri}/10/nl-NL/pay/#{@price_setting_id}/payments", {:query => {:key => @api_key, :product_id => 23, :order_id => 45, :payment_method_id =>2}, :headers => @headers })
          @ps.create_payment_with_custom_variables('nl-NL', {:product_id => 23, :order_id => 45, :payment_method_id =>2 }, 10)
        end
      end
      
      should "call class method POST and has a key named :your_variables" do
        mock.proxy(Zaypay::PriceSetting).post("#{@base_uri}//nl-NL/pay/#{@price_setting_id}/payments", {:query => {:key => @api_key, :product_id => 23, :order_id => 45, :payment_method_id =>2}, :headers => @headers })
        payment = @ps.create_payment_with_custom_variables('nl-NL', {:product_id => 23, :order_id => 45, :payment_method_id =>2 })
        assert payment[:payment][:your_variables]
        assert_equal 2, payment[:payment][:payment_method_id]
      end
    
      should "raise an exception if :payment_method_id is not given" do
        assert_raise RuntimeError do
          @ps.create_payment_with_custom_variables('nl-NL', {:product_id => 23, :order_id => 45 }, 10)
        end
      end
    end
    
    context "#create_payment_with_payalogue_id" do
      context "with optional amount" do
        should "call class method POST with the correct url" do
          mock.proxy(Zaypay::PriceSetting).post("#{@base_uri}/10/nl-NL/pay/#{@price_setting_id}/payments", {:query => {:key => @api_key, :payment_method_id => 2, :payalogue_id => 120474}, :headers => @headers })
          @ps.create_payment_with_payalogue_id(120474, 'nl-NL', 2, 10)
        end
      end
      
      should "call class method POST and return a payment with a key named :payalogue_url" do
        mock.proxy(Zaypay::PriceSetting).post("#{@base_uri}//nl-NL/pay/#{@price_setting_id}/payments", {:query => {:key => @api_key, :payment_method_id => 2, :payalogue_id => 120474}, :headers => @headers })
        payment = @ps.create_payment_with_payalogue_id(120474, 'nl-NL', 2)
        assert payment[:payment][:payalogue_url]
      end
    end

    context "#show_payment" do
      should "call class method GET and returns a hash with a key named :payment" do
        mock.proxy(Zaypay::PriceSetting).get("#{@base_uri}///pay/#{@price_setting_id}/payments/374277464", {:query => {:key => @api_key}, :headers => @headers } )
        payment = @ps.show_payment(374277464)
        assert payment.has_key?(:payment)
      end
    end

    context "#verification_code" do
      should "call class method POST and returns a hash with a key named :payment" do
        mock.proxy(Zaypay::PriceSetting).post("#{@base_uri}///pay/#{@price_setting_id}/payments/374277464/verification_code", {:query => {:key => @api_key, :verification_code => 1234}, :headers => @headers })
        payment = @ps.verification_code(374277464, 1234)
        assert payment.has_key?(:payment)
      end
    end
    
    context "#mark_payload_provided" do
      should "call class method POST and returns a payment with a key name :payload_provided" do
        mock.proxy(Zaypay::PriceSetting).post("#{@base_uri}///pay/#{@price_setting_id}/payments/374277464/mark_payload_provided", {:query => {:key => @api_key}, :headers => @headers })
        payment = @ps.mark_payload_provided(374277464)
        assert payment[:payment].has_key?(:payload_provided)
      end
    end

  end
end
