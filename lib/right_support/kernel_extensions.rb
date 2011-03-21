module RightSupport
  module KernelExtensions
    # Attempt to require one or more source files; if the require succeeds (or
    # if the files have already been successfully required), yield to the block.
    #
    # This method is useful to conditionally define code depending on the availability
    # of gems or standard-library source files. 
    #
    # === Parameters
    # Uses a parameters glob to pass all of its parameters transparently through to
    # Kernel#require.
    #
    # === Block
    # The block will be called if the require succeeds (if it does not raise LoadError).
    #
    # === Return
    # Preserves the return value of Kernel#require (generally either true or false).
    def if_require_succeeds(*args)
      result = require(*args)
      yield if block_given?
      return result
    rescue LoadError => e
      return false
    end
  end
end

class Object
  include RightSupport::KernelExtensions
end
