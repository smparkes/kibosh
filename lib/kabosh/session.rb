require 'pp'
require 'kabosh/exceptions'
require 'kabosh/response'

class Kabosh;end

class Kabosh::Session

  include Kabosh::Exceptions

  AsyncResponse = [-1, {}, []].freeze
    
  attr_reader :content, :sid

  def self.find request
    raise "hell"
  end

  class Response < Kabosh::Response
  end

  def initialize request
    @to = request["to"]
    @xml_lang = request["xml:lang"] 
    @ver = request["ver"] 
    @wait = request["wait"] 
    @hold = request["hold"]
    @route = request["route"]
    @from = request["from"]
    @ack = request["ack"]
    @content = request["content"] || "text/xml; charset=utf-8"

    @sid = ('%16.16f' % rand)[2..-1]

    yield Response.new(self).rack
  end

  def run request
    raise "hell"
  end

end
