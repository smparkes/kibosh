require 'nokogiri'

require 'kibosh/xmpp/request'

class Kibosh::XMPP
  def call(env)
    req = Rack::Request.new env
    return [400, {"Content-Type" => "text/plain"}, []] if !req.post?
    Kibosh::XMPP::Request.process(Nokogiri::XML::Document.parse(env["rack.input"].read))
  end
end



