#
# Copyright (c) 2011 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'openssl'
require 'net/ssh'

module RightSupport
  # The Validation module acts as a namespace for various submodules that provide
  # validation functions. These submodules can be mixed into classes in order to
  # add validation logic.
  #
  # As a convenience, to discourage mixin abuse, the Validation module includes
  # all of its submodules into its eigenclass at load-time. This means that every
  # validation method "is_foo" provided by _any_ submodule can be accessed simply
  # with a call to Validation.is_foo.
  #
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