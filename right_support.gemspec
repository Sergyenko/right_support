# -*- mode: ruby; encoding: utf-8 -*-

require 'rubygems'

spec = Gem::Specification.new do |s|
  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")

  s.name    = 'right_support'
  s.version = '0.5.0'
  s.date    = '2011-03-10'

  s.authors = ['Tony Spataro']
  s.email   = 'tony@rightscale.com'
  s.homepage= 'https://github.com/xeger/right_support'

  s.summary = %q{Reusable foundation code.}
  s.description = %q{A toolkit of useful foundation code: logging, input validation, that sort of thing.}

  s.add_runtime_dependency('rack', [">= 1.0"])
  s.add_runtime_dependency('net-ssh', ["~> 2.0"])

  s.add_development_dependency('rspec', ["~> 1.3"])
  s.add_development_dependency('flexmock', ["~> 0.8"])

  basedir = File.dirname(__FILE__)
  candidates = ['right_support.gemspec', 'MIT-LICENSE', 'README.rdoc'] + Dir['lib/**/*']
  s.files = candidates.sort
end
