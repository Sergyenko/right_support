require 'spec_helper'

describe RightSupport::SystemLogger do
  it 'escapes % characters to avoid confusing printf()' do
    @logger = RightSupport::SystemLogger.new('spec')
    flexmock(@logger).should_receive(:emit_syslog).with(Integer, 'All systems 100%% -- %%licious!')

    @logger.info('All systems 100% -- %licious!')
  end

  context ':split option' do
    it 'when true, splits multi-line messages' do
      @logger = RightSupport::SystemLogger.new('spec', :split=>true)
      flexmock(@logger).should_receive(:emit_syslog).times(5)

      @logger.info("This is a\nmulti line\r\nlog message\n\rwith all kinds\n\n\rof stuff")
    end

    it 'when false, passes through multi-line messages' do
      @logger = RightSupport::SystemLogger.new('spec', :split=>false)
      flexmock(@logger).should_receive(:emit_syslog).times(1)

      @logger.info("This is a\nmulti line\r\nlog message\n\rwith all kinds\n\n\rof stuff")
    end
  end

  context ':color option' do
    it 'when true, passes through ANSI color codes' do
      @logger = RightSupport::SystemLogger.new('spec', :color=>true)
      flexmock(@logger).should_receive(:emit_syslog).with(Integer, /[\e]/)

      @logger.info("This has \e[16;32mcolor\e[7;0m inside it!")
    end

    it 'when false, strips out ANSI color codes' do
      @logger = RightSupport::SystemLogger.new('spec', :color=>false)
      flexmock(@logger).should_receive(:emit_syslog).with(Integer, /[^\e]/)

      @logger.info("This has \e[16;32mcolor\e[7;0m inside it!")
    end
  end
end