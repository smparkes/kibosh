class Kibosh; end
class Kibosh::Sessions
  include Kibosh::Exceptions

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
