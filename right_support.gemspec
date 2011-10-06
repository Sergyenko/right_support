# -*- mode: ruby; encoding: utf-8 -*-

require 'rubygems'

spec = Gem::Specification.new do |s|
  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")

  s.name    = 'right_support'
  s.version = '1.0.3'
  s.date    = '2011-09-12'

  s.authors = ['Tony Spataro']
  s.email   = 'tony@rightscale.com'
  s.homepage= 'https://github.com/xeger/right_support'

  s.summary = %q{Reusable foundation code.}
  s.description = %q{A toolkit of useful foundation code: logging, input validation, etc.}

  s.add_development_dependency('rake', [">= 0.8.7"])
  s.add_development_dependency('ruby-debug', [">= 0.10"])
  s.add_development_dependency('rspec', ["~> 1.3"])
  s.add_development_dependency('cucumber', ["~> 0.8"])
  s.add_development_dependency('flexmock', ["~> 0.8"])
  s.add_development_dependency('net-ssh', ["~> 2.0"])
  s.add_development_dependency('rest-client', ["~> 1.6"])

  basedir = File.dirname(__FILE__)
  candidates = ['right_support.gemspec', 'LICENSE', 'README.rdoc'] + Dir['lib/**/*']
  s.files = candidates.sort
end
