# -*- mode: ruby -*-

require 'kibosh'

use Rack::Lint
use Rack::CommonLogger
use Rack::ShowExceptions
use Rack::Reloader, 0

run Kibosh.new
