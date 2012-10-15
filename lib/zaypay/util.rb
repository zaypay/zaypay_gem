module Zaypay
  
  # A class containing some utility methods.
  class Util

    # Symbolize keys recursively - Not just for hashes within a Hash, but also for hashes within an Array.
    #
    # = Example:
    # 
    #   hashie = { 'a' => 'A', 'b' => ['B'], 'c' => [ {'cc' => 'CC'} ], 'd' => { 'e' => 'E', :f => { :ff => 'FF' } } }
    #   Zaypay::Util.uber_symbolize(hashie)
    #
    #   => { :a => "A", :b => ["B"], :c => [ {:cc=>"CC"} ], :d => { :e => "E", :f => { :ff => "FF" } } } 
    #
    # @param data A hash or an array that you want to symbolize recursively
    # @return A hash or an array that has been symbolized recursively for you
    def self.uber_symbolize(data)
      if data.is_a?(Hash)
        data.keys.each do |key|
          data[(key.to_sym rescue key) || key] = data.delete(key)
        end
        data.values.each do |v|
          Zaypay::Util.uber_symbolize(v)
        end
      end
      if data.is_a?(Array)
        data.each{|e| Zaypay::Util.uber_symbolize(e)}
      end
      data
    end

    # Turns a hash with *:language* and *:country* keys to a string that represents the locale
    # 
    # = Example:
    #
    #   Zaypay::Util.stringify_locale_hash( { :country=>"NL", :language=>"nl" } ) 
    #   => 'nl-NL'
    #
    # @param [Hash] locale_hash a hash that represents the locale
    # @return [String] a string representing the locale in the format "language-country"
    def self.stringify_locale_hash(locale_hash)
      locale_hash[:language] << '-' << locale_hash[:country]
    end

    # Wraps something in an array if it is not an array
    def self.arrayify_if_not_an_array(obj)
      obj.is_a?(Array) ? obj : [obj]
    end
  end
end