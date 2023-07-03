require 'time'
require 'nokogiri'

module OPI
  class TimeoutError < StandardError; end
  class ConnectionError < StandardError; end
  class Error < StandardError; end
end

require_relative '../opi/string_hash'
require_relative '../opi/connection'
require_relative '../opi/xml_builder'
require_relative '../opi/request'
require_relative '../opi/handler'
