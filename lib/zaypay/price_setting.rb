module Zaypay
  require 'yaml'
  class PriceSetting
    attr_reader :price_setting_id, :key

    include HTTParty

    base_uri 'https://secure.zaypay.com'
    headers :Accept => 'application/xml'

    def initialize(price_setting_id=nil, key=nil)
      @price_setting_id, @key = price_setting_id, key
      select_settings
    end
  
    def locale_for_ip(ip)
      get "/#{ip}/pay/#{price_setting_id}/locale_for_ip" do |data|
        parts = data[:locale].split('-')
        {:country => parts[1], :language => parts[0]}
      end
    end

    def list_locales(amount=nil)
      get "/#{amount}/pay/#{price_setting_id}/list_locales" do |data|
        {:countries => data[:countries][:country],
         :languages => data[:languages][:language]}
      end
    end
  
    def list_countries(amount=nil)
      get "/#{amount}/pay/#{price_setting_id}/list_locales" do |data|
        data[:countries][:country]
      end
    end
    
    def list_languages(amount=nil)
      get "/#{amount}/pay/#{price_setting_id}/list_locales" do |data|
        data[:languages][:language]
      end
    end

    def list_payment_methods(locale, amount=nil)
      locale = stringify_locale_hash(locale) if locale.class == Hash
      get "/#{amount}/#{locale}/pay/#{price_setting_id}/payments/new" do |data|
        {:payment_methods => data[:payment_methods][:payment_method]}
      end
    end
  
    def create_payment(locale, payment_method_id, amount=nil)
      post "/#{amount}/#{locale}/pay/#{price_setting_id}/payments", :payment_method_id => payment_method_id do |data|
        payment_hash data
      end
    end
    
    # The following method allows the user to send custom variables to create the payment, which are then return as an element within the XML
    # When the following method is used, the custom_variables hash must contain a key named payment_method_id.
    # Otherwise the API may not select the user's desired payment_method 
    # However the payment_method is not returned to the report url
    def create_payment_with_custom_variables(locale, custom_variables={}, amount=nil)
      custom_variables.symbolize_keys!
      raise "the :payment_method_id key must be included in the custom_variables hash" if !custom_variables.has_key?(:payment_method_id)
      post "/#{amount}/#{locale}/pay/#{price_setting_id}/payments", custom_variables do |data|
        payment_hash data
      end
    end

    def create_payment_with_payalogue_id(payalogue_id, locale, payment_method_id, amount=nil)
      post "/#{amount}/#{locale}/pay/#{price_setting_id}/payments", :payment_method_id => payment_method_id, :payalogue_id => payalogue_id do |data|
        payment_hash data
      end
    end
    
    def show_payment(payment_id)
      get "///pay/#{price_setting_id}/payments/#{payment_id}" do |data|
        payment_hash data
      end
    end
  
    def verification_code(payment_id, verification_code)
      post "///pay/#{price_setting_id}/payments/#{payment_id}/verification_code", :verification_code => verification_code do |data|
        payment_hash data
      end
    end
  
    def mark_payload_provided(payment_id)
      post "///pay/#{price_setting_id}/payments/#{payment_id}/mark_payload_provided" do |data|
        payment_hash data
      end
    end

    protected  
    def select_settings
      unless @price_setting_id and @key
        begin
          config = YAML.load_file("#{Rails.root}/config/zaypay.yml")
        rescue => e
          puts 'Please either specify price_setting id and its API-key as first 2 arguments to #new, or create a config-file (checkout the plugin README)'
          raise e
        end
        @price_setting_id = config['default'] unless @price_setting_id
        @key = config[@price_setting_id]
      end
    end

    def method_missing(method, url, extra_query_string={})
      super unless [:get, :post, :put, :delete].include?(method)
      response = self.class.send(method, ('https://secure.zaypay.com' + url), {:query => default_query.merge!(extra_query_string), :headers => {'Accept' => 'application/xml' } })
      recursive_symbolize_keys! response
      check response
      block_given? ? yield(response[:response]) : response[:response]
    end
    
    def check(response)
      raise Zaypay::Error.new("HTTP-request to zaypay yielded status #{response.code}..\n\nzaypay said:\n#{response.body}") unless response.code == 200
      raise Zaypay::Error.new("HTTP-request to yielded an error:\n#{response[:response][:error]}") if response[:response].delete(:status)=='error'
    end
  
    def default_query
      {:key => key}
    end
    
    def recursive_symbolize_keys!(hash)
      hash.symbolize_keys!
      hash.values.select{|v| v.is_a? Hash}.each{|h| recursive_symbolize_keys!(h)}
    end
    
    def payment_hash(data)
      {:payment => data.delete(:payment), 
       :instructions => data}.delete_if{|k,v| v.nil?}
    end
    
    def stringify_locale_hash(locale_hash)
      locale_hash[:language] << '-' << locale_hash[:country]
    end
  end
end