require 'kibosh/exceptions'
require 'kibosh/session/stream'
require 'kibosh/xmpp/client/connection'

module Kibosh::XMPP; end
class Kibosh::XMPP::Session < Kibosh::Session; end

class Kibosh::XMPP::Session::Stream < Kibosh::Session::Stream

  include Kibosh::Exceptions

  attr_accessor :xmpp_id

  def version
    @session.version
  end

  def initialize session, request, response
    super do |response|
      yield response
    end
  end

  def connect request, response
    result = nil
    case string = request.driver( @session, @to, @route )
    when :local
      raise "implement"
    when String
      match = %r{^\s*([^:]+)(:(.*))?\s*$}.match string
      raise InternalServerError.new @session,
                                       "#{@to} unknown/unreachable via #{string}" if !match
      host = match[1]
      port = match[3] || 5222
      # p "***", response.body.to_xml
      raise "hell" if @body
      @body = response.defer
      # p "!!!", self.body.to_xml
      EM::connect host, port, Kibosh::XMPP::Client::Connection, self,
        lambda { |connection| 
          @connection = connection
        },
        lambda { |connection|
          self.body.extend(RemoteConnectionFailed)
          respond
        }
    when nil
      raise "implement"
    else
      raise UndefinedCondition.new @session, "No Kibosh route for #{@to}"
    end
    response
  end

  def handle request, response
    @connection.send_data request.body.inner_html
    response.defer
  end

end
