class Kibosh; end

class Kibosh::Response

  module Mixin
    attr_accessor :stream

    def rack
      if deferred
        raise "hell" if defer_fired || deliver_fired
        defer_fired = true
        v = [-1, {}, []].freeze
        puts "[ defer"
      else 
        raise "hell" if deliver_fired
        if @body["type"] == "terminate"
          @callback.receiver.instance_eval do
            @can_persist = false
          end
        end
        deliver_fired = true
        v = [ status || 200, headers, xml ]
        puts "[ #{v[2]}"
      end
      v
    end

    def status
      @session && @session.ver && 200 || @status
    end

    def status= status
      @status = status
    end

    def headers
      { "Content-Type" => @session ? @session.content : "text/xml; charset=utf-8" }
    end

    def body= body
      raise "hell" if @body
      @body = body
    end

    def body
      @body ||=
        begin
          document = Nokogiri::XML::Document.new
          body = document.create_element("body")
          body.attributes.merge! :xmlns => 'http://jabber.org/protocol/httpbind'
          document.root = body
        end
    end

    def xml
      @body.document.to_xml :save_with => 0
    end

  end

  include Mixin

  attr_reader :session, :stream

  def session
    @session
  end

  def session= session
    raise "hell" if @session
    @session = session
  end

  def initialize async_callback, close_callback
    raise "hell" if !Method === async_callback
    @callback = async_callback
    @closed = close_callback
    @callback.receiver.comm_inactivity_timeout = 0
    @fired = @deferred = false
    @created_at = Time.now
  end

  attr_reader :created_at
  attr_accessor :delivered, :deliver_fired, :defer_fired, :deferred

  def defer
    body = @body
    @body = nil
    @session.defer self
    body
  end

  def on_close &block
    @closed.callback &(@close_block = block)
  end

  def _cancel!
    raise "hell" if delivered || !deferred
    self.deferred = false
    @callback.call nil
    self.delivered = true
    @closed = nil
    @callback = nil
  end

  def _deliver
    raise "hell" if delivered || !deferred
    @closed.cancel_callback @close_block
    self.deferred = false
    @callback.call rack
  end

end
