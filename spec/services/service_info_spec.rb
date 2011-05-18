require 'spec_helper'

describe RightSupport::Services::ServiceInfo do
  context :from_file do
    before(:all) do
      @filename = Tempfile.new('right_support').path
      @settings = { 'awesome' => {'class' => 'StubAwesomeService', 'endpoints' => [1, 2, 3], 'cuckoo' => 'clock'} }
      File.open(@filename, 'w') { |f| f.puts YAML.dump(@settings) }
    end

    it 'constructs a file-backed ServiceInfo' do
      info = RightSupport::Services::ServiceInfo.from_file(@filename)
      info.should_not be_nil
      info['awesome'].should_not be_nil
      info['awesome'].should == @settings['awesome']
    end
  end
end