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

  def initialize object, request, response
    case object
    when Kibosh::XMPP::Session::Stream
      other = object
      super
      response.stream = self
      (@connection = other.connection).restart self
    when Kibosh::XMPP::Session
      super { |response| yield response }
    else
      raise "hell"
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

  def restart request, response
    self.class.new self, request, response
    self.abort
    response.defer
    response
  end

  def handle request, response
    if request.body.inner_html && request.body.inner_html != ""
      puts "> #{request.body.inner_html}"
      @connection.send_data request.body.inner_html
    end
    if request.body["type"] == "terminate"
      @connection.terminate
      terminate request, response
    else
      response.defer
      response
    end
  end

  def ready!
    if @body["type"] == "terminate" and @body["condition"] == "remote-stream-error"
      terminate!
    end
    super
  end

end
