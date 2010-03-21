require 'kibosh/exceptions'

class Kibosh;end

class Kibosh::Router
  
  include Kibosh::Exceptions

  def initialize map
    @map = map
  end

  def driver session, to, route
    driver = @map.detect do |pair|
      key, value = pair
      case key
      when String
        key == to
      when Regexp
        key.match to
      end
    end
    raise HostUnknown.new session, "#{to} unknown/unreachable" if !driver
    driver[1]
  end

end

