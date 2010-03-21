class Kibosh::Session; end
class Kibosh::Session::Stream
  
  attr_reader :to
  attr_accessor :from

  module Response
    def self.extended response
      response.body["from"] = response.stream.from if response.stream.from
      response.body["stream"] = response.stream.id
    end
  end

  def initialize session, request, response
    @session = session
    @to = request["to"]
    @route = request["route"]
    @driver = request.driver @session, @to, @route
    session.streams << self
    response.stream = self
    yield connect request, response.extend(Response)
  end

  def body
    @body ||=
      begin
        document = Nokogiri::XML::Document.new
        body = document.create_element("body")
        body["xmlns"] = 'http://jabber.org/protocol/httpbind'
        body["stream"] = id
        document.root = body
      end
  end

  def body= body
    raise "hell" if @body
    @body = body
  end

  def respond
    @body = @session.respond @body
  end

  def ready!
    respond
  end

  def id
    @id ||= ('%16.16f' % rand)[2..-1]
  end

end
