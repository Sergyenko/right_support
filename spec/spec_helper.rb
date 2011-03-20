require 'rubygems'
require 'bundler/setup'
require 'flexmock'

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