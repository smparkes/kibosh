# -*- mode: ruby -*-

require 'kabosh'

use Rack::Lint
use Rack::CommonLogger
use Rack::ShowExceptions
use Rack::Reloader, 0

run Kabosh.new
