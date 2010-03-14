require 'sinatra/base'

module TestFlock; end

class TestFlock::Sinatra < ::Sinatra::Base

  get '/' do
    "TestFlock::Sinatra"
  end

end
