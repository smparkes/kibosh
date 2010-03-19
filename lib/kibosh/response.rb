class Kibosh; end

class Kibosh::Response

  def initialize session
    @content = session.content
    @document = Nokogiri::XML::Builder.new do
      body(:xmlns => 'http://jabber.org/protocol/httpbind',
           :sid => session.sid) {
      }
    end.to_xml
  end

  def rack
    s = @document.to_s
    r = [ 200,
          {"Content-Type"=>@content,
           "Content-Length"=>s.length.to_s
          }, [s] ]
    p r
    r
  end

end
