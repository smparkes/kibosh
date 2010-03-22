require 'kibosh/session'
require 'kibosh/xmpp/session/stream'

module Kibosh::XMPP; end
class Kibosh::XMPP::Session < Kibosh::Session

  module CreateSessionRequest
    def self.extended response
      response.attributes.merge! :"xmpp:version" => response.session.version,
                                 :"xmlns:xmpp" => "urn:xmpp:xbosh" if response.session.version
    end
  end

  def initialize request, response
    client[:version] = Version.new(request["version"]) if request["version"]
    super do |response|
      yield response
    end
  end

  def version
    @version ||= client[:version]
  end

  def handle request, response
    restart = (attr = request.body.attribute_with_ns("restart",'urn:xmpp:xbosh')) && attr.value == "true"
    if restart
      to = request.body["to"]
      request.body.remove_attribute "to"
      stream = streams[request]
      request.body["to"] = to if to
      stream.restart request, response
    else
      super
    end
  end

end
