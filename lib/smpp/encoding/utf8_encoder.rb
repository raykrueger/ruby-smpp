require 'iconv'

module Smpp
  module Encoding

    # This class is not required by smpp.rb at all, you need to bring it in yourself.
    # This class also requires iconv, you'll need to ensure it is installed.
    class Utf8Encoder

      EURO_TOKEN = "_X_EURO_X_"

      GSM_ESCAPED_CHARACTERS = {
        ?(  => "\173", # {
        ?)  => "\175", # }
        184 => "\174", # |
        ?<  => "\133", # [
        ?>  => "\135", # ]
        ?=  => "\176", # ~
        ?/  => "\134", # \
        134 => "\136", # ^
        ?e  =>  EURO_TOKEN
      }

      def encode(data_coding, short_message)
        if data_coding < 2
          sm = short_message.gsub(/\215./) do |match|
            lookup = match[1]
            alternate_lookup = lookup.bytes.first if has_encoding?(lookup)
            GSM_ESCAPED_CHARACTERS[lookup] || GSM_ESCAPED_CHARACTERS[alternate_lookup]
          end
          sm = Iconv.conv("UTF-8", "HP-ROMAN8", sm)
          euro_token = "\342\202\254"
          euro_token.force_encoding("UTF-8") if has_encoding?(euro_token)
          sm.gsub(EURO_TOKEN, euro_token)
        elsif data_coding == 8
          Iconv.conv("UTF-8", "UTF-16BE", short_message)
        else
          short_message
        end
      end

      private

      def has_encoding?(str)
        str.respond_to?(:encoding)
      end
    end
  end
end
