require 'nokogiri'

require 'kabosh/request'

class Kabosh
  VERSION = '0.0.0'

  def call(env)
    req = Rack::Request.new env
    pp req
    return [400, {"Content-Type" => "text/plain"}, []] if !req.post?
    Kabosh::Request.process(Nokogiri::XML::Document.parse(env["rack.input"].read))
  end

end



