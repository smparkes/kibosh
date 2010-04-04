class Kibosh::Session; end
class Kibosh::Session::Stream
  
  module Response
    def self.extended response
      response.body["from"] = response.stream.from if response.stream.from && !response.stream.from_sent
      response.body["secure"] = response.stream.secure if response.stream.secure && !response.stream.secure_sent
      response.body["stream"] = response.stream.id
    end
  end

  attr_reader :to, :session, :route, :driver, :connection
  attr_accessor :from, :secure

  def initialize object, request, response
    case object
    when Kibosh::Session::Stream
      other = object
      @session = other.session
      @to = other.to
      @route = other.route
      @driver = other.driver
      session.streams << self
    when Kibosh::Session
      session = object
      @session = session
      @to = request["to"]
      @route = request["route"]
      @driver = request.driver @session, @to, @route
      session.streams << self
      response.stream = self
      yield connect request, response.extend(Response)
    else
      raise "hell"
    end
  end

  def stop
    # FIX
    body["type"] = "terminate"
    body["condition"] = "system-shutdown"
    respond
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
    raise "hell" if @body || !body.nil?
    @body = body
  end

  def lock body
    if body.object_id == @body.object_id
      @body = nil
    end
  end

  def respond
    @body = @session.respond @body
  end

  def ready!
    respond
  end

  def terminate request, response
    document = Nokogiri::XML::Document.new
    body = document.create_element("body")
    body["xmlns"] = 'http://jabber.org/protocol/httpbind'
    # body["stream"] = id (?)
    response.body = document.root = body
    abort
    response
  end

  def terminate!
    abort
  end

  def id
    @id ||= ('%16.16f' % rand)[2..-1]
  end

  def close
    raise "implement"
    abort
  end

  def abort
    session.streams.delete self
  end

end
