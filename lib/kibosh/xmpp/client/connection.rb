class Kibosh; end
module Kibosh::XMPP; end
module Kibosh::XMPP::Client; end

class Kibosh::XMPP::Client::Connection < EM::Connection

  def initialize stream, success, failure
    super
    @stream = stream
    @success = success
    @failure = failure
  end

  def post_init
  end

  class StreamParser < Nokogiri::XML::SAX::PushParser

    class Document < Nokogiri::XML::SAX::Document
      def initialize stream, success, failure
        super()
        @stream = stream
        @success = success
        @failure = failure
        @established = false
        @current = {:parent => nil, :parameters => nil, :children => []}
      end 

      def start_element_namespace name, attrs = [], prefix = nil, uri = nil, ns = []
        if !@established && name == "stream" && uri == "http://etherx.jabber.org/streams"
          if name == "stream" && uri == "http://etherx.jabber.org/streams"
            @established = true
            id = nil
            from = nil
            attrs.each do |attr|
              case attr.localname
              when "id"; id = attr.value
              when "from"
                @stream.body["from"] = from = attr.value
              end
            end
            @success.call "id" => id, "from" => from if @success
            @success = @failure = nil
          else
            @failiure.call if @failure
            @success = @failure = nil
          end
        else
          @current[:children].push :parent => @current,
                                   :parameters => [ name, attrs, prefix, uri, ns ],
                                   :children => []
          @current = @current[:children].last
        end
      end

      def end_element name
        @current = @current[:parent]
        if @current == nil 
          # should be EOS
          raise "#{name}"
        elsif @current[:parent] == nil

          # require 'pp'; pp @current

          body = @stream.body
          document = body.document

          # pp document

          add = lambda do |parent, children|
            children.each do |child|
              params = child[:parameters]
              if params == :characters
                document.create_text_node child[:children] do |node|
                  parent.add_child node
                end
                next
              elsif params == :cdata
                parent.add_child(Nokogiri::XML::CDATA.new document, string)
                next
              end
              name, attrs, prefix, uri, ns_array = params
              document.create_element name do |node|
                nses = ns_array.inject({}) do |hash,pair|
                  hash[pair[0]] = pair[1]
                  hash
                end
                if prefix and prefix != "" and !nses.has_key? prefix
                  if document.namespaces.has_key? prefix 
                    raise document.namespaces[prefix].inspect
                  end
                  nses[prefix] = document.root.add_namespace prefix, uri
                end
                # p name, prefix, nses[prefix]
                if prefix
                  node.namespace = nses[prefix]
                end
                attrs.each do |attr|
                  node[attr.localname] = attr.value
                end
                ns_array.each do |pair|
                  node.add_namespace *pair
                end
                add.call node, child[:children]
                parent.add_child node
              end
            end
          end

          add.call @stream.body, @current[:children]
          @current = {:parent => nil, :parameters => nil, :children => []}

          @stream.ready!
        end
      end

      def characters string
        @current[:children].push :parent => @current,
                                 :parameters => :characters,
                                 :children => string
      end

      def cdata_block string
        @current[:children].push :parent => @current,
                                 :parameters => :cdata,
                                 :children => string
      end

      def error error
        raise "hell"
      end

    end

    def initialize stream, success, failure
      super Document.new( stream, success, failure), nil, "UTF-8"
    end
  end

  def connection_completed
    stream_element = Nokogiri::XML::Builder.new do |xml|
      xml.send :"stream:stream", :to => @stream.to,
                                 :xmlns => "jabber:client",
                                 :"xmlns:stream" => "http://etherx.jabber.org/streams",
                                 :version => @stream.version do
        xml.text "*"
      end
    end.to_xml :indent => 0
    midway = stream_element.index "*"
    prefix = stream_element[0..midway-1]
    puts "> #{prefix}"
    @suffix = stream_element[midway+1..-1]
    @parser = StreamParser.new @stream, lambda { |attributes|
      @stream.xmpp_id = attributes["id"]
      @stream.from = attributes["from"]
      @success.call self if @success
      @success = @failure = nil
    }, lambda {
      @failiure.call self if @failure
      @success = @failure = nil
    }
    send_data prefix
  end

  def receive_data data
    puts "< #{data}"
    @parser << data
  end
  
  def unbind
    @failure.call self if @failure
    @success = @failure = nil
  end

  def restart
    connection_completed
  end

end


