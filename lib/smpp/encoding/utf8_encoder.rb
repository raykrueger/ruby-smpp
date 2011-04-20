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
        134 => "\252", # ^
        ?e  =>  EURO_TOKEN
      }

      def encode(data_coding, short_message)
        if data_coding < 2
          sm = short_message.gsub(/\215./) { |match| GSM_ESCAPED_CHARACTERS[match[1]] }
          sm = Iconv.conv("UTF-8", "HP-ROMAN8", sm)
          sm.gsub(EURO_TOKEN, "\342\202\254")
        elsif data_coding == 8
          Iconv.conv("UTF-8", "UTF-16BE", short_message)
        else
          short_message
        end
      end
    end
  end
end
