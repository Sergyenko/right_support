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

RANDOM_KEY_CLASSES   = [String, Integer, Float, TrueClass, FalseClass]
RANDOM_VALUE_CLASSES = RANDOM_KEY_CLASSES + [Array, Hash]

def random_value(klass=nil, depth=0)
  if klass.nil?
    if depth < 3
      klasses = RANDOM_VALUE_CLASSES
    else
      klasses = RANDOM_KEY_CLASSES
    end

    klass = klasses[rand(klasses.size)]
  end

  if klass == String
    result = ''
    rand(40).times { result << (?a + rand(26)) }
  elsif klass == Integer
    result = rand(0xffffff)
  elsif klass == Float
    result = rand(0xffffff) * rand
  elsif klass == TrueClass
    result = true
  elsif klass == FalseClass
    result = false
  elsif klass == Array
    result = []
    rand(10).times { result << random_value(nil, depth+1) }
  elsif klass == Hash
    result = {}
    key_type = RANDOM_KEY_CLASSES[rand(RANDOM_KEY_CLASSES.size)]
    rand(10).times { result[random_value(key_type, depth+1)] = random_value(nil, depth+1) }
  else
    raise ArgumentError, "Unknown random value type #{klass}"
  end

  result
end