class Kibosh; end
class Kibosh::Sessions
  include Kibosh::Exceptions

  def initialize env

    EM.tick_loop {} # workound EM issue

    class << env['async.callback'].receiver.backend
      def stop
        @stop_callback.call if @stop_callback
        super
      end
      def stop_callback &block
        @stop_callback = block
      end
    end
    env['async.callback'].receiver.backend.stop_callback do
      @list.each { |stream| stream.stop }
    end
  end

  def hash
    @hash ||= {}
  end

  def list
    @list ||= []
  end

  def [] sid
    hash[sid] or raise Error.new ItemNotFound, "no session with sid #{sid}"
  end

  def << session
    raise Error.new InternalServerError, "session with sid #{session.sid} already defined", session if hash[session.sid]
    hash[session.sid] = session
    list << session
  end
end
