require 'kibosh/request'
require 'kibosh/xmpp'
require 'kibosh/xmpp/session'

class Kibosh::XMPP::Request < Kibosh::Request
  Session = Kibosh::XMPP::Session
end
