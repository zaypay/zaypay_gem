module Zaypay
  require 'yaml'
  
  # PriceSetting instances allows you to communicate to the Zaypay platform.
  #
  # It is basically a Ruby wrapper for the Zaypay-API, which provides you a bunch of payment-related methods, as well as some utility methods.
  class PriceSetting
    include HTTParty
    attr_reader :price_setting_id, :api_key
    attr_accessor :locale, :payment_method_id

    base_uri 'https://secure.zaypay.com'
    headers :Accept => 'application/xml'

    # Creates instances of Zaypay::PriceSetting.
    # 
    # To instantiate, one must provide a PriceSetting-id and its API-Key.
    # You can obtain these information once you have created a PriceSetting on the Zaypay platform (http://www.zaypay.com).
    #
    # You can also call the "one-arg" or the "no-args" version of the initializer,
    # but to do that, you must first create config/zaypay.yml in your Rails app, see the {file:/README.rdoc README} file.
    #
    # @param [Integer] price_setting_id your PriceSetting's id
    # @param [String] api_key your PriceSetting's api-key
    def initialize(price_setting_id=nil, api_key=nil)
      @price_setting_id, @api_key = price_setting_id, api_key
      select_settings
    end

    def locale=(arg)
      case arg
      when Hash
        if arg.has_key?(:language) && arg.has_key?(:country)
          @locale = Zaypay::Util.stringify_locale_hash(arg)
        else
          raise Zaypay::Error.new(:locale_not_set, "The hash you provided was invalid. Please make sure it contains the keys :language and :country")
        end
      when String
        @locale = arg
      end
    end
    
    # Returns the default locale as a string for a given ip_address, with the first part representing the language, the second part the country
    #
    # This method comes in handy when you want to preselect the language and country when your customer creates a payment on your website.
    #
    # = Example: 
    #    # We take an ip-address from Great Britain for example:
    #    ip = "212.58.226.75"
    #    @price_setting.locale_string_for_ip(ip)
    #    => 'en-GB'
    #
    # Also see {#locale_for_ip}
    # @param [String] ip an ip-address (e.g. from your site's visitors)
    # @return [String] a string that represents the default locale for the given IP, in a language-country format.
    def locale_string_for_ip(ip)
      get "/#{ip}/pay/#{price_setting_id}/locale_for_ip" do |data|
        parts = data[:locale].split('-')
        Zaypay::Util.stringify_locale_hash({:country => parts[1], :language => parts[0]})
      end
    end
    
    # Returns the default locale as a hash for a given ip_address.
    #
    # It is similar to {#locale_string_for_ip}, except that this method returns the locale as a hash
    # This method comes in handy when you want to preselect only the langauge or the country for your customer
    #
    # = Example: 
    #    # We take an ip-address from Great Britain for example:
    #    ip = "212.58.226.75"
    #    @price_setting.locale_string_for_ip(ip)
    #    => { :country => 'GB', :language => 'en' }
    #
    # @param [String] ip an ip-address (e.g. from your site's visitors)
    # @return [Hash] a hash with :country and :language as keys
    def locale_for_ip(ip)
      get "/#{ip}/pay/#{price_setting_id}/locale_for_ip" do |data|
        parts = data[:locale].split('-')
        {:country => parts[1], :language => parts[0]}
      end
    end

    # Returns a country as a Hash, if the country of the given IP has been configured for your Price Setting.
    #
    # If the country of the given IP has been configured for this Price Setting, it returns a hash with *:country* and *:locale* subhashes, else it returns *nil*.
    #
    # @param [String] ip an ip-address (e.g. from your site's visitors)
    # @return [Hash] a hash containing *:country* and *:locale* subhashes
    def country_has_been_configured_for_ip(ip, options={})
      # options can take a :amount key
      locale  = locale_for_ip(ip)
      country = list_countries(options).select{ |c| c.has_value? locale[:country] }.first
      {:country => country, :locale => locale} if country
    end

    # Returns a hash containing the countries and languages that are available to your Price Setting.
    #
    # @param [Hash] options an options-hash that can take an *:amount* option, in case you want to use dynamic amounts
    # @return [Hash] a hash containing subhashes of countries and languages
    def list_locales(options={})
      get "/#{options[:amount]}/pay/#{price_setting_id}/list_locales" do |data|
        {:countries => Zaypay::Util.arrayify_if_not_an_array(data[:countries][:country]),
         :languages => data[:languages][:language]}
      end
    end

    # Returns an array of countries that are available to your Price Setting.
    #
    # @param [Hash] options an options-hash that can take an *:amount* option, in case you want to use dynamic pricing
    # @return [Array] an array of countries, each represented by a hash with *:code* and *:name*
    def list_countries(options={})
      get "/#{options[:amount]}/pay/#{price_setting_id}/list_locales" do |data|
        Zaypay::Util.arrayify_if_not_an_array(data[:countries][:country])
      end
    end

    # Returns an array of languages that are available to your Price Setting.
    #
    # @param [Hash] options an options-hash that can take an *:amount* option, in case you want to use dynamic pricing
    # @return [Array] an array of languages, each represented by a hash with *:code*, *:english_name*, *:native_name*
    def list_languages(options={})
      get "/#{options[:amount]}/pay/#{price_setting_id}/list_locales" do |data|
        data[:languages][:language]
      end
    end

    # Returns an array of payment methods that are available to your Price Setting with a given locale
    #
    # @param [Hash] options an options-hash that can take an *:amount* option, in case you want to use dynamic amounts
    # @return [Array] an array of payment methods, each represented by a hash.
    # @raise [Zaypay::Error] in case you call this method before setting a locale
    def list_payment_methods(options={})
      raise Zaypay::Error.new(:locale_not_set, "locale was not set for your price setting") if @locale.nil?
      get "/#{options[:amount]}/#{@locale}/pay/#{price_setting_id}/payments/new" do |data|
        Zaypay::Util.arrayify_if_not_an_array(data[:payment_methods][:payment_method])
      end
    end

    # Creates a payment on the Zaypay platform.
    # 
    # You can provide an options-hash, which will add additional data to your payment. The following keys have special functionalities:
    #
    #   :amount        # Enables dynamic pricing. It must be an integer representing the price in cents.
    #   :payalogue_id  # Adds the URL of the payalogue specified to your payment as :payalogue_url.
    #
    # Any other keys will be added to a key named :your_variables, which can be used for your future reference. Please check the {file:/README.rdoc README} for the structure of the payment returned.
    #
    # = Example: 
    #    @price_setting.create_payment(:payalogue_id => payalogue_id, :amount => optional_amount, :my_variable_1 => "value_1", :my_variable_2 => "value_2")
    # 
    # @param [Hash] options an options-hash that can take an *:amount*, *:payalogue_id* as options, and any other keys can be used as your custom variables for your own reference
    # @return [Hash] a hash containing data of the payment you just created
    # @raise [Zaypay::Error] in case you call this method before setting a *locale* or a *payment_method_id*
    def create_payment(options={})
      raise Zaypay::Error.new(:locale_not_set, "locale was not set for your price setting") if @locale.nil?
      raise Zaypay::Error.new(:payment_method_id_not_set, "payment_method_id was not set for your price setting") if @payment_method_id.nil?
      query = {:payment_method_id => payment_method_id}
      query.merge!(options)
      amount = query.delete(:amount)
      post "/#{amount}/#{@locale}/pay/#{price_setting_id}/payments", query do |data|
        payment_hash data
      end
    end

    # Returns the specified payment as a hash.
    #
    # @param [Integer] payment_id your payment's id
    # @return [Hash] a hash containing data of the specified payment
    def show_payment(payment_id)
      get "///pay/#{price_setting_id}/payments/#{payment_id}" do |data|
        payment_hash data
      end
    end

    # Submits a verification code to the Zaypay platform.
    #
    # In some countries, the end-user must submit a verification code in order to complete a payment. Please refer to the {file:/README.rdoc README} for more details
    # 
    # @param [Integer] payment_id the id of the payment that needs to be finalized
    # @param [Integer] verification_code a code that the end-user receives through an sms and that he must submit to complete this payment
    # @return [Hash] a hash containing data of the specified payment
    def verification_code(payment_id, verification_code)
      post "///pay/#{price_setting_id}/payments/#{payment_id}/verification_code", :verification_code => verification_code do |data|
        payment_hash data
      end
    end

    # Posts a request to the Zaypay platform to mark that you have delivered the 'goodies' to your customer. 
    #
    # Please refer to {file:/README.rdoc README} for more details.
    #
    # @param [Integer] payment_id the payment's id
    # @return [Hash] a hash containing data of the specified payment
    def mark_payload_provided(payment_id)
      post "///pay/#{price_setting_id}/payments/#{payment_id}/mark_payload_provided" do |data|
        payment_hash data
      end
    end

    protected
    def select_settings
      unless @price_setting_id and @api_key
        begin
          config = YAML.load_file("#{Rails.root}/config/zaypay.yml")
        rescue => e
          puts 'Please either specify price_setting id and its API-key as first 2 arguments to #new, or create a config-file (checkout the plugin README)'
          raise e
        end

        config_error = Zaypay::Error.new(:config_error, "You did not provide a price_setting id or/and an API-key. You can either pass it to the constructor or create a config file (check out README)")
        raise config_error unless config

        @price_setting_id = config['default'] unless @price_setting_id
        @api_key = config[@price_setting_id]
        if @api_key.nil? || @price_setting_id.nil?
          raise config_error
        end
      end
    end

    def method_missing(method, url, extra_query_string={})
      super unless [:get, :post, :put, :delete].include?(method)
      response = self.class.send(method, ('https://secure.zaypay.com' + url), {:query => default_query.merge!(extra_query_string), 
                                                                              :headers => {'Accept' => 'application/xml' } })
      
      Zaypay::Util.uber_symbolize(response)
      check response
      block_given? ? yield(response[:response]) : response[:response]
    end

    def check(response)
      raise Zaypay::Error.new(:http_error, "HTTP-request to zaypay yielded status #{response.code}..\n\nzaypay said:\n#{response.body}") unless response.code == 200
      raise Zaypay::Error.new(:http_error, "HTTP-request to yielded an error:\n#{response[:response][:error]}") if response[:response].delete(:status)=='error'
    end

    def default_query
      {:key => api_key}
    end

    def payment_hash(data)
      {:payment => data.delete(:payment),
       :instructions => data}.delete_if{|k,v| v.nil?}
    end
  end
end