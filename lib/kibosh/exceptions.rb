require 'nokogiri'
require 'kibosh/response'

class Kibosh; end

module Kibosh::Exceptions

  class Error < ::Exception
    def initialize mod, message, session = nil
      raise "hell" if !(Module === mod)
      super message
      @module = mod
      @session = session
    end
    def extend response
      response.extend @module
      if message and message !~ /^\s*$/
        body = response.body
        document = body.document
        body.add_child( document.create_element "text" ).add_child(document.create_text_node message)
      end
    end
  end

  module Terminal
    def self.included other
      (class << other; self; end).send :define_method, :extended do |object|
        body = response = nil
        if Kibosh::Response === object
          response = object
          body = response.body
        else
          body = object
        end
        body["type"] = "terminate"
        body["condition"] = condition
        response and response.status ||= respond_to?(:status) ? status : nil
      end
    end
  end

  module BadRequest
    include Terminal
    def self.condition; "bad-request"; end
    def self.status; 400; end
  end

  module HostUnknown
    include Terminal
    def self.condition; "host-unknown"; end
  end

  module ImproperAddressing
    include Terminal
    def self.condition; "improper-addressing"; end
  end

  module ItemNotFound
    include Terminal
    def self.condition; "item-not-found"; end
  end

  module InternalServerError
    include Terminal
    def self.condition; "internal-server-error"; end
  end

  module RemoteConnectionFailed
    include Terminal
    def self.condition; "remote-connection-failed"; end
  end

  module RemoteStreamError
    include Terminal
    def self.condition; "remote-stream-error"; end
  end

  module UndefinedCondition
    include Terminal
    def self.condition; "undefined-condition"; end
  end

  module PolicyViolation
    include Terminal
    def self.condition; "policy-violation"; end
    def self.status; 403; end
  end

  module ItemNotFound
    include Terminal
    def self.condition; "item-not-found"; end
    def self.status; 404; end
  end

end
