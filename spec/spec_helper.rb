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

def corrupt(key, factor=4)
  d = key.size / 2

  key[0..(d-factor)] + key[d+factor..-1]
end

def find_empirical_distribution(trials=2500, list=[1,2,3,4,5])
  seen = {}

  trials.times do
    value = yield(list)
    seen[value] ||= 0
    seen[value] += 1
  end

  seen
end

def test_random_distribution(trials=25000, list=[1,2,3,4,5], &block)
  seen = find_empirical_distribution(trials, list, &block)
  should_be_chosen_fairly(seen,trials,list.size)
end

def should_be_chosen_fairly(seen,trials,size)
  #Load should be evenly distributed
  chance = 1.0 / size
  seen.each_pair do |_, count|
    (Float(count) / Float(trials)).should be_close(chance, 0.025) #allow 5% margin of error
  end
end



