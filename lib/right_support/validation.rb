require 'openssl'
require 'net/ssh'

module RightSupport
  module Validation

  end
end

Dir[File.expand_path('../validation/*.rb', __FILE__)].each do |filename|
  require filename
end

RightSupport::Validation.constants.each do |const|
  const = RightSupport::Validation.const_get(const) #string to constant
  RightSupport::Validation.extend(const)
end