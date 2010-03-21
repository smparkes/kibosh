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

end
