require 'pp'
require 'kibosh/exceptions'
require 'kibosh/response'
require 'kibosh/session/stream'

class Kibosh;end

class Kibosh::Session

  include Kibosh::Exceptions

  attr_reader :sid, :content

  def self.find request
    raise "hell"
  end

  class Version
    include Comparable
    attr_reader :major, :minor
    def initialize ver
      m = %r{^(\d+).(\d+)$}.match ver
      raise BadRequest.new nil, "Bad version format: #{ver}" if !m
      @major, @minor = m[1].to_i, m[2].to_i
    end
    def <=> other
      diff = @major - other.major
      if diff == 0
        diff = @minor - other.minor
      end
      diff
    end
    def to_s
      "#{@major}.#{@minor}"
    end
  end

  class Streams
    def initialize session
      @session = session
    end
    def hash
      @hash ||= {}
    end
    def list
      @list ||= []
    end
    def [] key
      case key
      when Kibosh::Request
        if key['to']
          raise "implement new stream"
        else
          if key['stream'] || list.length != 1
            self[ key['stream'] ]
          else
            list.first
          end
        end
      else
        stream = hash[key]
        raise Error.new ItemNotFound, "no stream with id '#{key}'", @session if !stream
        stream
      end
    end
    def << stream
      raise "hell #{stream.id}" if hash[stream.id]
      hash[stream.id] = stream
      list << stream
    end
  end

  def streams
    @streams ||= Streams.new self
  end

  module NewSessionResponse
    def self.extended response
      session = response.session
      body = response.body
      [:sid, :wait, :ver, :polling, :inactivity, :requests,
       :hold, :accept, :maxpause, :charsets ].each do |symbol|
        value = session.send symbol
        body[symbol.to_s] = value.to_s if !value.nil?
      end
    end
  end

  def initialize request, response
    @responses = []
    @bodies = []

    client[:xml_lang] = request["xml:lang"] 
    client[:ver] = Version.new(request["ver"]) if request["ver"]
    client[:wait] = Integer(request["wait"]) if request["wait"]
    client[:hold] = Integer(request["hold"]) if request["hold"]
    client[:from] = request["from"]
    client[:ack] = Integer(request["ack"]) if request["ack"]
    client[:content] = request["content"]

    @sid = ('%16.16f' % rand)[2..-1]
    @content = request["content"]

    response.session = self

    self.class.const_get(:Stream).new self,
                                       request,
                                       response.extend(NewSessionResponse) do |response|
      yield response
    end
  end


  def handle request, response
    if stream = streams[request]
      stream.handle request, response
    else
      raise "hell: new stream"
    end
  end

  def wait
    @wait ||= !client[:wait] && 60 || [ client[:wait], 60 ].min
  end

  def ver
    @ver ||= (!client[:ver] && Version.new("1.8") ||
               client[:ver] < Version.new("1.8") ?
               client[:ver] :
               Version.new("1.8")).to_s
  end

  def polling
    @polling ||= 5
  end
  
  def inactivity
    @polling ||= 60
  end

  def requests
    @requests ||= hold+1
  end

  def hold
    @hold ||= client[:hold] ? client[:hold] : 1;
  end

  def accept
  end

  def maxpause
    @maxpause ||= 60*5
  end 

  def charsets
  end

  def respond body
    # p "respond"
    raise "hell" if !body
    if response = @responses.shift
      # p "respond pop"
      raise "hell" if !response.deferred || response.delivered
      response.body = body
      response._deliver
      body = nil
    else
      # p "respond push"
      @bodies << body
    end
    body
  end

  def defer response
    # p "defer"
    raise "hell" if response.deliver_fired || response.deferred
    if body = @bodies.shift
      lock body
      response.body = body
    else
      # p "defer push"
      response.deferred = true
      @responses << response
    end
  end

  private
  
  def client
    @client ||= {}
  end

end

