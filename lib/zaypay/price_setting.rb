module Zaypay
  require 'yaml'
  class PriceSetting
    include HTTParty
    attr_reader :price_setting_id, :key
    attr_accessor :locale, :payment_method_id

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

    def locale_string_for_ip(ip)
      get "/#{ip}/pay/#{price_setting_id}/locale_for_ip" do |data|
        parts = data[:locale].split('-')
        Zaypay::Util.stringify_locale_hash({:country => parts[1], :language => parts[0]})
      end
    end

    def ip_country_is_configured?(ip, options={})
      # country_code = locale_for_ip(ip)[:country]
      locale  = locale_for_ip(ip)
      country = list_countries(options).select{ |c| c.has_value? locale[:country] }.first
      {:country => country, :locale => locale} if country
    end

    # returns a hash containing keys countries and languages
    def list_locales(options={})
      get "/#{options[:amount]}/pay/#{price_setting_id}/list_locales" do |data|
        {:countries => Zaypay::Util.arrayify_if_not_an_array(data[:countries][:country]),
         :languages => data[:languages][:language]}
      end
    end

    # returns an array with countries
    def list_countries(options={})
      get "/#{options[:amount]}/pay/#{price_setting_id}/list_locales" do |data|
        Zaypay::Util.arrayify_if_not_an_array(data[:countries][:country])
      end
    end

    # returns an array with languages
    def list_languages(options={})
      get "/#{options[:amount]}/pay/#{price_setting_id}/list_locales" do |data|
        data[:languages][:language]
      end
    end

    def list_payment_methods(options={})
      raise "locale was not set" if @locale.nil?
      get "/#{options[:amount]}/#{@locale}/pay/#{price_setting_id}/payments/new" do |data|
        Zaypay::Util.arrayify_if_not_an_array(data[:payment_methods][:payment_method])
      end
    end

    # Example: @price_setting.create_payment(:custom_variable => "my value", :payalogue_id => payalogue_id, :amount => optional_amount )
    def create_payment(options={})
      raise "locale was not set for your price setting" if @locale.nil?
      raise "payment_method_id was not set for your price setting" if @payment_method_id.nil?
      query = {:payment_method_id => payment_method_id}
      query.merge!(options)
      amount = query.delete(:amount)
      post "/#{amount}/#{@locale}/pay/#{price_setting_id}/payments", query do |data|
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
        if @key.nil? || @price_setting_id.nil?
          raise "You did not provide a price_setting id or/and an API-key. You can either pass it to the constructor or create a config file (check out README)" 
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
      raise Zaypay::Error.new("HTTP-request to zaypay yielded status #{response.code}..\n\nzaypay said:\n#{response.body}") unless response.code == 200
      raise Zaypay::Error.new("HTTP-request to yielded an error:\n#{response[:response][:error]}") if response[:response].delete(:status)=='error'
    end

    def default_query
      {:key => key}
    end

    def payment_hash(data)
      {:payment => data.delete(:payment),
       :instructions => data}.delete_if{|k,v| v.nil?}
    end
  end
end