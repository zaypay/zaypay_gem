module Zaypay
  class Util

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

    def self.stringify_locale_hash(locale_hash)
      locale_hash[:language] << '-' << locale_hash[:country]
    end

    def self.arrayify_if_not_an_array(obj)
      obj.is_a?(Array) ? obj : [obj]
    end

  end
end