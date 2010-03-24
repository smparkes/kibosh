require 'kibosh/router'
require 'kibosh/sessions'
require 'kibosh/request'
require 'kibosh/exceptions'

class Kibosh
  VERSION = '0.0.0'

  include Kibosh::Exceptions

  def initialize options = {}
    @router = Router.new options[:hosts]
  end

  def call(env)
    @sessions ||= Sessions.new(env)
    Request.handle(env,@sessions,@router)
  end

end
