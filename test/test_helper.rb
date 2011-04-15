require "rubygems"
require "test/unit"
require File.expand_path(File.dirname(__FILE__) + "../../lib/smpp")

require "stringio"

Smpp::Base.logger = Logger.new(StringIO.new)