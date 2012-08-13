require 'test_helper'
require 'zaypay'

class PriceSettingTest < Test::Unit::TestCase

  context "Zaypay::PriceSetting" do

    setup do
      @price_setting_id = 111111
      @payalogue_id = 222222
      @payment_id = 999999999
      @api_key = '999a99999999aa9aaa99aa9a99a99a9a'
      @ps = Zaypay::PriceSetting.new(@price_setting_id, @api_key)
      @optional_amount = 10
      
      @base_uri = 'https://secure.zaypay.com'
      @headers = {'Accept' => 'application/xml' }
      @ip = '12.34.456.89'
    end

    context "#initialize" do
      context "with no-args" do
        should "lookup for zaypay.yml within Rails config directory and use the default" do
          YAML.expects(:load_file).with('anywhere/config/zaypay.yml').returns({ @price_setting_id => @api_key, "default"=>@price_setting_id})
          ps = Zaypay::PriceSetting.new
          assert_equal @price_setting_id, ps.price_setting_id
          assert_equal @api_key, ps.key
        end
        should "raise Error if yml is blank" do
          assert_raise RuntimeError do
            YAML.expects(:load_file).with('anywhere/config/zaypay.yml').returns({})
            Zaypay::PriceSetting.new
          end
        end
        should "raise Error if the yml file is not present" do
          assert_raise Errno::ENOENT do
            Zaypay::PriceSetting.new
          end
        end
      end

      context "with price_setting_id and key" do
        should "not lookup for zaypay.yml within Rails config directory" do
          YAML.expects(:load_file).never
          ps = Zaypay::PriceSetting.new(@price_setting_id, @api_key)
          assert_equal @price_setting_id, ps.price_setting_id
          assert_equal @api_key, ps.key
        end
      end

      context "only price_setting_id is provided" do
        context "with a valid yml file" do
          should "return a PriceSetting with price_setting_id and key" do
            YAML.expects(:load_file).with('anywhere/config/zaypay.yml').returns({@price_setting_id => @api_key})
            ps = Zaypay::PriceSetting.new(@price_setting_id)
            assert_equal @price_setting_id, ps.price_setting_id
            assert_equal @api_key, ps.key
          end
        end
        context "without a valid yml file" do  
          should "raise RuntimeError" do
            assert_raise RuntimeError do
              YAML.expects(:load_file).with('anywhere/config/zaypay.yml').returns({})
              ps = Zaypay::PriceSetting.new(@price_setting_id)
            end
          end
        end
      end
    end

    context "#locale_for_ip" do
      setup do
        FakeWeb.register_uri(:get,"#{@base_uri}/#{@ip}/pay/#{@ps.price_setting_id}/locale_for_ip?key=#{@api_key}", :body => 'test/locale_for_ip.xml', :content_type => "text/xml")
        @response =  HTTParty.get("#{@base_uri}/#{@ip}/pay/#{@ps.price_setting_id}/locale_for_ip", {:query => {:key => @api_key}, :headers => @headers })
      end
      should "call class method get with the correct url" do
        Zaypay::PriceSetting.expects(:get).with("#{@base_uri}/#{@ip}/pay/#{@ps.price_setting_id}/locale_for_ip", {:query => {:key => @api_key}, :headers => @headers }).returns @response
        @ps.locale_for_ip(@ip)
      end
      should "return a country-language hash" do
        Zaypay::PriceSetting.expects(:get).with("#{@base_uri}/#{@ip}/pay/#{@ps.price_setting_id}/locale_for_ip", {:query => {:key => @api_key}, :headers => @headers }).returns @response
        locale = @ps.locale_for_ip(@ip)
        assert locale.has_key?(:country)
        assert locale.has_key?(:language)
      end
    end

    context "#locale_string_for_ip" do
      setup do
        FakeWeb.register_uri(:get,"#{@base_uri}/#{@ip}/pay/#{@ps.price_setting_id}/locale_for_ip?key=#{@api_key}", :body => 'test/locale_for_ip.xml', :content_type => "text/xml")
        @response =  HTTParty.get("#{@base_uri}/#{@ip}/pay/#{@ps.price_setting_id}/locale_for_ip", {:query => {:key => @api_key}, :headers => @headers })
      end
      
      should "call class method get with the correct url" do
        Zaypay::PriceSetting.expects(:get).with("#{@base_uri}/#{@ip}/pay/#{@ps.price_setting_id}/locale_for_ip", {:query => {:key => @api_key}, :headers => @headers }).returns @response
        @ps.locale_string_for_ip(@ip)
      end
      should "return a string with the correct locale" do
        Zaypay::PriceSetting.expects(:get).with("#{@base_uri}/#{@ip}/pay/#{@ps.price_setting_id}/locale_for_ip", {:query => {:key => @api_key}, :headers => @headers }).returns @response
        assert_equal 'nl-NL', @ps.locale_string_for_ip(@ip)
      end
    end

    context "#list_locales" do
      setup do
        FakeWeb.register_uri(:get, "#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales?key=#{@api_key}", :body => 'test/multi_countries_ps.xml', :content_type => "text/xml")
        @response = HTTParty.get("#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales", {:query => {:key => @api_key}, :headers => @headers })
      end

      context "with optional amount" do
        should "call class method GET with the correct url" do
          Zaypay::PriceSetting.expects(:get).with("#{@base_uri}/#{@optional_amount}/pay/#{@ps.price_setting_id}/list_locales",
                                                  {:query => {:key => @api_key}, :headers => @headers }).returns @response
          @ps.list_locales(:amount => @optional_amount)
        end
      end

      context "without optional amount" do
        should "call class method GET with the correct url" do
          Zaypay::PriceSetting.expects(:get).with("#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales", {:query => {:key => @api_key}, :headers => @headers }).returns @response
          @ps.list_locales
        end
      end

      should "return a hash containing a langauages hash and a countries hash" do
        Zaypay::PriceSetting.expects(:get).with("#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales", {:query => {:key => @api_key}, :headers => @headers }).returns @response
        locales = @ps.list_locales
        assert locales.has_key?(:countries)
        assert locales.has_key?(:languages)
      end
      
      should "always wrap up countries in an array" do
        FakeWeb.register_uri(:get, "#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales?key=#{@api_key}", :body => 'test/single_country_ps.xml', :content_type => "text/xml")
        @single_country_response = HTTParty.get("#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales", {:query => {:key => @api_key}, :headers => @headers })
        Zaypay::PriceSetting.expects(:get).with("#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales", 
                                                {:query => {:key => @api_key}, :headers => @headers }).returns @single_country_response

        assert @ps.list_locales[:countries].is_a?(Array)
      end
    end

    context "#list_countries" do
      context "with multiple countries" do
        setup do
          FakeWeb.register_uri(:get,"#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales?key=#{@api_key}", :body => 'test/multi_countries_ps.xml', :content_type => "text/xml")
          @response =  HTTParty.get("#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales", {:query => {:key => @api_key}, :headers => @headers })
        end
        context "with optional amount" do
          should "call class method get with the correct url" do
            Zaypay::PriceSetting.expects(:get).with("#{@base_uri}/#{@optional_amount}/pay/#{@price_setting_id}/list_locales", 
                                                    {:query => {:key => @api_key}, :headers => @headers } ).returns @response
            @ps.list_countries(:amount => @optional_amount)
          end
        end
        context "without optional amount" do
          should "call class method get with the correct url" do
            Zaypay::PriceSetting.expects(:get).with("#{@base_uri}//pay/#{@price_setting_id}/list_locales", 
                                                    {:query => {:key => @api_key}, :headers => @headers } ).returns @response
            @ps.list_countries
          end
        end
        should "returns an array identical to #list_locales[:countries]" do
          Zaypay::PriceSetting.expects(:get).with("#{@base_uri}//pay/#{@price_setting_id}/list_locales", 
                                                  {:query => {:key => @api_key}, :headers => @headers } ).twice.returns @response
          results = @ps.list_countries
          assert results.kind_of?(Array)
          assert_equal results, @ps.list_locales[:countries]
        end
      end

      context "with one country" do
        should "always return an array even for single-country price_settings" do
          FakeWeb.register_uri(:get,"#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales?key=#{@api_key}", :body => 'test/single_country_ps.xml', :content_type => "text/xml")
          @single_country_response =  HTTParty.get("#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales", {:query => {:key => @api_key}, :headers => @headers })
          Zaypay::PriceSetting.expects(:get).with("#{@base_uri}//pay/#{@price_setting_id}/list_locales", 
                                                  {:query => {:key => @api_key}, :headers => @headers } ).returns @single_country_response
          assert @ps.list_countries.is_a?(Array)
        end
      end 
    end

    context "#list_languages" do
      setup do
        FakeWeb.register_uri(:get,"#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales?key=#{@api_key}", :body => 'test/multi_countries_ps.xml', :content_type => "text/xml")
        @response =  HTTParty.get("#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales", {:query => {:key => @api_key}, :headers => @headers })
      end
      context "with optional amount" do
        should "call class method get with the correct url" do
          Zaypay::PriceSetting.expects(:get).with("#{@base_uri}/#{@optional_amount}/pay/#{@price_setting_id}/list_locales", 
                                                  {:query => {:key => @api_key}, :headers => @headers }).returns @response
          @ps.list_languages(:amount => @optional_amount)
        end
      end
      context "without optional amount" do
        should "call class method get with the correct url" do
          Zaypay::PriceSetting.expects(:get).with("#{@base_uri}//pay/#{@price_setting_id}/list_locales", 
                                                  {:query => {:key => @api_key}, :headers => @headers }).returns @response
          @ps.list_languages
        end
      end
      should "returns array identical to #list_locales[:languages]" do
        Zaypay::PriceSetting.expects(:get).with("#{@base_uri}//pay/#{@price_setting_id}/list_locales", 
                                                {:query => {:key => @api_key}, :headers => @headers }).twice.returns(@response)
        results = @ps.list_languages
        assert_equal true, results.kind_of?(Array)
        assert_equal results, @ps.list_locales[:languages]
      end
    end

    context "#list_payment_methods" do
  
      setup do
        FakeWeb.register_uri(:get, "#{@base_uri}//nl-NL/pay/#{@price_setting_id}/payments/new", :body => 'test/multiple_payment_methods.xml', :content_type => "text/xml" )
        @multi_methods_response = HTTParty.get("#{@base_uri}//nl-NL/pay/#{@price_setting_id}/payments/new", {:headers => @headers })
        FakeWeb.register_uri(:get, "#{@base_uri}//nl-BE/pay/#{@price_setting_id}/payments/new", :body => 'test/single_payment_method.xml', :content_type => "text/xml" )
        @single_method_response = HTTParty.get("#{@base_uri}//nl-BE/pay/#{@price_setting_id}/payments/new", {:headers => @headers })
      end

      context "the locale is set" do
        setup do
          @ps.locale = 'nl-NL' 
        end

        def mock_payment_methods(optional_amount=nil)
          response = @ps.locale == 'nl-NL' ? @multi_methods_response : @single_method_response
          Zaypay::PriceSetting.expects(:get).with("#{@base_uri}/#{optional_amount}/#{@ps.locale}/pay/#{@price_setting_id}/payments/new", 
                                                  {:query => {:key => @api_key}, :headers => @headers }).returns response
        end

        should "not need any args" do
          mock_payment_methods
          @ps.list_payment_methods
        end

        should "return an array when multiple payment methods are available" do
          mock_payment_methods
          nl_payment_methods = @ps.list_payment_methods
          assert_equal 2, nl_payment_methods.size
          assert nl_payment_methods.is_a?(Array)
        end
      
        should "return an array when only one payment method is available" do
          @ps.locale = 'nl-BE'
          mock_payment_methods
          be_payment_methods = @ps.list_payment_methods
          assert_equal 1, be_payment_methods.size
          assert be_payment_methods.is_a?(Array)
        end
      
        context "and an optional amount" do
          should "call class method GET with the correct url" do
            mock_payment_methods(@optional_amount)
            payment_methods = @ps.list_payment_methods(:amount => @optional_amount)
          end
        end
      end
      
      context "the locale is not set" do
        should "throw an error" do
          assert_raise RuntimeError, "hey did not raise the exception you expected" do
            @ps.list_payment_methods
          end
        end
      end

    end

    context "#create_payment" do
      setup do
        FakeWeb.register_uri(:post,"#{@base_uri}//nl-NL/pay/#{@price_setting_id}/payments?key=#{@api_key}", :body => 'test/create_payment.xml', :content_type => "text/xml")
        @response =  HTTParty.post("#{@base_uri}//nl-NL/pay/#{@price_setting_id}/payments", {:query => {:key => @api_key}, :headers => @headers })
      end

      should "call class method POST with correct URL" do
        Zaypay::PriceSetting.expects(:post).with("#{@base_uri}//nl-NL/pay/#{@price_setting_id}/payments", 
                                                  {:query => {:key => @api_key, :payment_method_id => 2}, :headers => @headers }).returns @response
        @ps.locale = "nl-NL"
        @ps.payment_method_id = 2
        @ps.create_payment
      end

      should "return a hash with a :payment and :instructions keys" do
        Zaypay::PriceSetting.expects(:post).with("#{@base_uri}//nl-NL/pay/#{@price_setting_id}/payments", 
                                                  {:query => {:key => @api_key, :payment_method_id => 2}, :headers => @headers }).returns @response
        @ps.locale = "nl-NL"
        @ps.payment_method_id = 2
        payment = @ps.create_payment
        assert payment.has_key?(:payment)
        assert payment.has_key?(:instructions)
      end
      
      should "raise an error when no locale has been set" do
        assert_raise RuntimeError do
          @ps.payment_method_id = 2 
          @ps.create_payment
        end
      end

      should "raise an error when no payment_method_id has been set" do
        assert_raise RuntimeError do
          @ps.locale = 'nl-NL'
          @ps.create_payment
        end
      end

      context "with an options hash" do
        context "containing custom_variables" do
          should "call class method POST with the correct url" do
            Zaypay::PriceSetting.expects(:post).with("#{@base_uri}//nl-NL/pay/#{@price_setting_id}/payments", {:query => {:key => @api_key,
                                                                                                                         :payment_method_id => 2,
                                                                                                                         :product_id => 23,
                                                                                                                         :purchase_id => 45 },
                                                                                                               :headers => @headers }).returns @response
            @ps.locale = "nl-NL"
            @ps.payment_method_id = 2
            @ps.create_payment(:product_id => 23, :purchase_id => 45)
          end
        end

        context "including a payalogue_id key" do
          should "call class method POST with the correct url" do
            Zaypay::PriceSetting.expects(:post).with("#{@base_uri}//nl-NL/pay/#{@price_setting_id}/payments", {:query => {:key => @api_key,
                                                                                                                         :payment_method_id => 2,
                                                                                                                         :payalogue_id => @payalogue_id },
                                                                                                               :headers => @headers }).returns @response
            @ps.locale = "nl-NL"
            @ps.payment_method_id = 2
            @ps.create_payment(:payalogue_id => @payalogue_id )
          end
        end

        context "including an optional amount" do
          should "call class method POST with the correct url" do
            Zaypay::PriceSetting.expects(:post).with("#{@base_uri}/#{@optional_amount}/nl-NL/pay/#{@price_setting_id}/payments", {:query => {:key => @api_key,
                                                                                                                         :payment_method_id => 2 },
                                                                                                               :headers => @headers }).returns @response
            @ps.locale = "nl-NL"
            @ps.payment_method_id = 2
            @ps.create_payment(:amount => @optional_amount )
          end
        end

        context "with custom_variables and payalogue_id" do
          should "call class method POST with the correct url" do
            Zaypay::PriceSetting.expects(:post).with("#{@base_uri}//nl-NL/pay/#{@price_setting_id}/payments", {:query => {:key => @api_key, 
                                                                                                                          :product_id => 23, 
                                                                                                                          :purchase_id => 45,
                                                                                                                          :payalogue_id => @payalogue_id, 
                                                                                                                          :payment_method_id => 2 }, 
                                                                                                                          :headers => @headers }).returns @response
            @ps.locale = "nl-NL"
            @ps.payment_method_id = 2
            @ps.create_payment(:product_id => 23, :purchase_id => 45, :payalogue_id => @payalogue_id )
          end
        end

        context "with custom_variable, payalogue_id and optional_amount" do
          should "call class method POST with the correct url" do
            Zaypay::PriceSetting.expects(:post).with("#{@base_uri}/#{@optional_amount}/nl-NL/pay/#{@price_setting_id}/payments", {:query => {:key => @api_key,
                                                                                                                                             :product_id => 23,
                                                                                                                                             :purchase_id => 45,
                                                                                                                                             :payalogue_id => @payalogue_id,
                                                                                                                                             :payment_method_id => 2 },
                                                                                                                                  :headers => @headers }).returns @response
            @ps.locale = 'nl-NL'
            @ps.payment_method_id = 2
            @ps.create_payment( :product_id => 23, :purchase_id => 45, :payalogue_id => @payalogue_id, :amount => @optional_amount)
          end
        end
      end
    end

    context "#show_payment" do
      setup do
        FakeWeb.register_uri(:get,"#{@base_uri}///pay/#{@price_setting_id}/payments/#{@payment_id}?key=#{@api_key}", :body => 'test/show_payment.xml', :content_type => "text/xml")
        @response =  HTTParty.get("#{@base_uri}///pay/#{@price_setting_id}/payments/#{@payment_id}", {:query => {:key => @api_key}, :headers => @headers })
      end
      should "call class method GET and returns a hash with a key named :payment" do
        Zaypay::PriceSetting.expects(:get).with("#{@base_uri}///pay/#{@price_setting_id}/payments/#{@payment_id}", {:query => {:key => @api_key}, :headers => @headers } ).returns @response
        payment = @ps.show_payment(@payment_id)
        assert payment.has_key?(:payment)
      end
    end

    context "#verification_code" do
      setup do
        FakeWeb.register_uri(:post,"#{@base_uri}///pay/#{@price_setting_id}/payments/#{@payment_id}/verification_code?key=#{@api_key}&verification_code=1234", 
                             :body => 'test/verification_code.xml', :content_type => "text/xml")
        @response =  HTTParty.post("#{@base_uri}///pay/#{@price_setting_id}/payments/#{@payment_id}/verification_code", 
                                    {:query => {:key => @api_key, :verification_code => 1234}, :headers => @headers })
      end
      should "call class method POST and returns a hash with a key named :payment" do
        Zaypay::PriceSetting.expects(:post).with("#{@base_uri}///pay/#{@price_setting_id}/payments/#{@payment_id}/verification_code", 
                                                 {:query => {:key => @api_key, :verification_code => 1234}, :headers => @headers } ).returns @response
        payment = @ps.verification_code(@payment_id, 1234)
        assert payment.has_key?(:payment)
      end
    end

    context "#mark_payload_provided" do
      setup do
        FakeWeb.register_uri(:post, "#{@base_uri}///pay/#{@price_setting_id}/payments/#{@payment_id}/mark_payload_provided?key=#{@api_key}", 
                             :body => 'test/mark_payload_provided.xml', :content_type => "text/xml")
        @response =   HTTParty.post("#{@base_uri}///pay/#{@price_setting_id}/payments/#{@payment_id}/mark_payload_provided", 
                                    {:query => {:key => @api_key}, :headers => @headers })
      end
      should "call class method POST and returns a payment with a key name :payload_provided" do
        Zaypay::PriceSetting.expects(:post).with("#{@base_uri}///pay/#{@price_setting_id}/payments/#{@payment_id}/mark_payload_provided", 
                                                  { :query => {:key => @api_key}, :headers => @headers }).returns @response
        payment = @ps.mark_payload_provided(@payment_id)
        assert payment[:payment].has_key?(:payload_provided)
      end
    end

    context "#ip_country_within_configured_countries" do
      setup do
        FakeWeb.register_uri(:get,"#{@base_uri}/#{@ip}/pay/#{@ps.price_setting_id}/locale_for_ip?key=#{@api_key}", :body => 'test/locale_for_ip.xml', :content_type => "text/xml")
        @ip_response =  HTTParty.get("#{@base_uri}/#{@ip}/pay/#{@ps.price_setting_id}/locale_for_ip", {:query => {:key => @api_key}, :headers => @headers })
      end
      context "when ip_country is NOT configured" do
        setup do
          # IP country is the Netherlands but we have a price_setting configured for Belgium only
          FakeWeb.register_uri(:get, "#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales?key=#{@api_key}", :body => 'test/single_country_ps.xml', :content_type => "text/xml")
          @single_country_response = HTTParty.get("#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales", {:query => {:key => @api_key}, :headers => @headers })
        end
        
        should "return nil" do
          Zaypay::PriceSetting.expects(:get).with("#{@base_uri}/#{@ip}/pay/#{@ps.price_setting_id}/locale_for_ip", 
                                                  {:query => {:key => @api_key}, :headers => @headers }).returns @ip_response
          Zaypay::PriceSetting.expects(:get).with("#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales", 
                                                  {:query => {:key => @api_key}, :headers => @headers }).returns @single_country_response
          assert_nil @ps.ip_country_is_configured?(@ip)
        end
      end

      context "ip_country is within configured countries" do
        context "when ip_country IS configured" do
          setup do
            FakeWeb.register_uri(:get, "#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales?key=#{@api_key}", :body => 'test/multi_countries_ps.xml', :content_type => "text/xml")
            @multi_country_response = HTTParty.get("#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales", {:query => {:key => @api_key}, :headers => @headers })
          end
          should "return a country-hash " do
            Zaypay::PriceSetting.expects(:get).with("#{@base_uri}/#{@ip}/pay/#{@ps.price_setting_id}/locale_for_ip", 
                                                    {:query => {:key => @api_key}, :headers => @headers }).returns @ip_response
            Zaypay::PriceSetting.expects(:get).with("#{@base_uri}//pay/#{@ps.price_setting_id}/list_locales", 
                                                    {:query => {:key => @api_key}, :headers => @headers }).returns @multi_country_response
            assert_equal({:country => {:name => 'Netherlands', :code => 'NL'}, :locale => {:country => 'NL', :language => 'nl'}} , @ps.ip_country_is_configured?(@ip))
          end
        end
      end
    end

  end
end
