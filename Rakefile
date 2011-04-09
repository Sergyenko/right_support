# -*-ruby-*-
require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/clean'
require 'spec/rake/spectask'
require 'cucumber/rake/task'

desc "Run unit tests"
task :default => :spec

desc "Run unit tests"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = Dir['**/*_spec.rb']
  t.spec_opts = lambda do
    IO.readlines(File.join(File.dirname(__FILE__), 'spec', 'spec.opts')).map {|l| l.chomp.split " "}.flatten
  end
end

desc "Run functional tests"
Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = %w{--color --format pretty}
end

desc 'Generate documentation for the rightscale_foundation gem.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'rightscale_foundation'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Build rightscale_foundation gem"
Rake::GemPackageTask.new(Gem::Specification.load("right_support.gemspec")) do |package|
  package.need_zip = true
  package.need_tar = true
end

CLEAN.include('pkg')
