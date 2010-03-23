require 'nokogiri'

require 'kibosh/exceptions'
require 'kibosh/session'
require 'kibosh/xmpp/session'

class Kibosh;end

class Kibosh::Request

  Session = Kibosh::Session

  include Kibosh::Exceptions

  def self.handle env, sessions, router
    request = Rack::Request.new env
    response = Kibosh::Response.new(env['async.callback'], env['async.close'])
    begin
      raise Error.new BadRequest, "HTTP verb is not POST" if !request.post?

      begin
        xml = env["rack.input"].read
      rescue Exception => e
        raise Error.new BadRequest, "Could not fetch request data: " + e
      end 

      begin
        doc = Nokogiri::XML::Document.parse(xml)
      rescue Exception => e
        raise Error.new BadRequest, "Could not parse XML: " + e
      end

      puts "] #{doc.to_xml}"
      
      new(doc,router).handle(response, sessions)
    rescue Error => e
      $stderr.puts e
      $stderr.puts e.backtrace.join("\n")
      e.extend(response)
    rescue Exception => e
      $stderr.puts e
      $stderr.puts e.backtrace.join("\n")
      Error.new(UndefinedCondition, e.to_s).extend(response)
    end
    response.rack
  end
  
  attr_reader :body

  def initialize xml, router
    @body = xml.root
    @router = router
    if @body.node_name != "body"
      raise Error.new BadRequest, "root element is #{@body.node_name} not body"
    end
  end

  def handle response, sessions
    if sid = self["sid"]
      response = (response.session = sessions[sid]).handle(self, response)
    else
      s = session.new self, response do |r|
        response = r
      end
      sessions << s
    end
    response
  end

  def [] s
    @body[s]
  end

  def session
    if @body.attribute_with_ns "version", "urn:xmpp:xbosh"
      Kibosh::XMPP::Session
    else
      Kibosh::Session
    end
  end

  def driver session, to, route
    @router.driver session, to, route
  end

end
