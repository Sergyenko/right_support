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

Spec::Matchers.define :have_green_endpoint do |endpoint|
  match do |balancer|
    stack = balancer.instance_variable_get(:@stack)
    state = stack.instance_variable_get(:@endpoints)
    state = state[endpoint] if state.respond_to?(:[])
    unless stack && state && state.key?(:n_level)
      raise ArgumentError, "Custom matcher is incompatible with new HealthCheck implementation!"
    end
    state[:n_level] == 0
  end
end

Spec::Matchers.define :have_yellow_endpoint do |endpoint, n|
  match do |balancer|
    stack = balancer.instance_variable_get(:@stack)
    max_n = stack.instance_variable_get(:@yellow_states)
    state = stack.instance_variable_get(:@endpoints)
    state = state[endpoint] if state.respond_to?(:[])
    unless max_n && stack && state && state.key?(:n_level)
      raise ArgumentError, "Custom matcher is incompatible with new HealthCheck implementation!"
    end

    if n
      state[:n_level].should == n
    else
      (1...max_n).should include(state[:n_level])
    end
  end
end

Spec::Matchers.define :have_red_endpoint do |endpoint|
  match do |balancer|
    stack = balancer.instance_variable_get(:@stack)
    max_n = stack.instance_variable_get(:@yellow_states)
    state = stack.instance_variable_get(:@endpoints)
    state = state[endpoint] if state.respond_to?(:[])
    unless max_n && stack && state && state.key?(:n_level)
      raise ArgumentError, "Custom matcher is incompatible with new HealthCheck implementation!"
    end
    min = 1
    state[:n_level].should == max_n
  end
end

def find_empirical_distribution(trials=2500, list=[1,2,3,4,5])
  seen = {}

  trials.times do
    value = yield
    seen[value] ||= 0
    seen[value] += 1
  end

  seen
end

def test_random_distribution(trials=25000, list=[1,2,3,4,5], &block)
  seen = find_empirical_distribution(trials, &block)
  should_be_chosen_fairly(seen,trials,list.size)
end

def should_be_chosen_fairly(seen,trials,size)
  #Load should be evenly distributed
  chance = 1.0 / size
  seen.each_pair do |_, count|
    (Float(count) / Float(trials)).should be_close(chance, 0.025) #allow 5% margin of error
  end
end



