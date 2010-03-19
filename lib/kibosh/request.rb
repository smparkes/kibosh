require 'kabosh/exceptions'
require 'kabosh/session'

class Kabosh;end

class Kabosh::Request

  include Kabosh::Exceptions

  AsyncResponse = [-1, {}, []].freeze
    
  def self.process xml
    new(xml).run
  rescue BadRequest => e
    [ 400, {"Content-Type" => "text/plain"}, [e.to_s] ]
  rescue Error => e
    [ 500, {"Content-Type" => "text/plain"}, [e.to_s] ]
  end
  
  def initialize xml
    @body = xml.root
    if @body.node_name != "body"
      raise BadRequest.new "root element is #{@body.node_name} not body"
    end
    pp @body
  end

  def run
    if self["sid"]
      response = Kabosh::Session.find(sid).run(self)
    else
      Kabosh::Session.new self do |r|
        response = r
      end
    end
    response
  end

  def [] s
    @body[s]
  end

end


