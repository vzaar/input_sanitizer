require 'time'
require 'date'
require 'stringio'

module InputSanitizer
  class ConversionError < Exception
  end

  class IntegerConverter
    def call(value)
      cast = value.to_i
      if cast.to_s != value.to_s
        raise ConversionError.new("invalid integer")
      end
      cast
    end
  end

  class FloatConverter
    def call(value)
      Float(value)
    rescue ArgumentError
      raise ConversionError.new("invalid decimal")
    end
  end

  class StringConverter
    def call(value)
      value.to_s
    end
  end

  class StringIOConverter
    def call(value)
      StringIO.new(value.to_s)
    end
  end

  class NotBlankStringConverter < InputSanitizer::StringConverter
    def call(value)
      if value.nil? || value == ""
        raise ConversionError.new("empty string")
      else
        super(value)
      end
    end
  end

  class DateConverter
    ISO_RE = /\A\d{4}-?\d{2}-?\d{2}/

    def call(value)
      raise ConversionError.new("invalid time") unless value =~ ISO_RE
      Date.parse(value)
    rescue ArgumentError
      raise ConversionError.new("invalid iso8601 date")
    end
  end

  class TimeConverter
    ISO_RE = /\A\d{4}-?\d{2}-?\d{2}([T ]?\d{2}(:?\d{2}(:?\d{2}((\.)?\d{0,3}(Z)?)?)?)?)?\Z/

    def call(value)
      case value
      when Time
        value.getutc
      when String
        if value =~ ISO_RE
          strip_timezone(Time.parse(value))
        else
          raise ConversionError.new("invalid time")
        end
      else
        raise ConversionError.new("invalid time")
      end
    rescue ArgumentError
      raise ConversionError.new("invalid time")
    end

    def strip_timezone(time)
      Time.utc(time.year, time.month, time.day, time.hour, time.min, time.sec)
    end
  end

  class BooleanConverter
    BOOLEAN_MAP = {
      true => true,
      false => false,
      'true' => true,
      'false' => false,
      'True' => true,
      'False' => false,
      '1' => true,
      '0' => false,
      'yes' => true,
      'no' => false,
      1 => true,
      0 => false,
    }

    def call(value)
      if BOOLEAN_MAP.has_key?(value)
        BOOLEAN_MAP[value]
      else
        truthy, falsy = BOOLEAN_MAP.partition { |_, value| value }
        truthy = truthy.map { |e| "'#{e[0]}'" }.uniq
        falsy = falsy.map { |e| "'#{e[0]}'" }.uniq

        message = "Invalid boolean: use "
        message += truthy.join(", ")
        message += " for true, or "
        message += falsy.join(", ")
        message += " for false."
        raise ConversionError.new(message)
      end
    end
  end

  module AllowNil
    def call(value)
      if value.nil? || value == ""
        nil
      else
        super(value)
      end
    end
  end
end
