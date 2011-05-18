require 'rubygems'
require 'bundler/setup'
require 'flexmock'
require 'tempfile'

Spec::Runner.configure do |config|
  config.mock_with :flexmock
end

$basedir = File.expand_path('../..', __FILE__)
$libdir  = File.join($basedir, 'lib')
require File.join($libdir, 'right_support')

def read_fixture(fn)
  fixtures_dir = File.join($basedir, 'spec', 'fixtures')
  File.read(File.join(fixtures_dir, fn))
end

def corrupt(key, factor=4)
  d = key.size / 2

  key[0..(d-factor)] + key[d+factor..-1]
end

class StubAwesomeService
  def initialize(settings)
    @settings = settings
  end
end

module UselessNamespace
  AliasedAwesomeService = ::StubAwesomeService
end