require 'spec_helper'

describe RightSupport::Services::ServiceInfoFile do
  before(:all) do
    @filename = Tempfile.new('right_support').path
    @settings = { 'awesome' => {'class' => 'StubAwesomeService',
                                'settings' =>
                                    {'endpoints' => [1, 2, 3], 'cuckoo' => 'clock'}
                                }
                }
    File.open(@filename, 'w') { |f| f.puts YAML.dump(@settings) }
  end

  it 'freshens when the file is modified on disk' do
    si = RightSupport::Services::ServiceInfoFile.new(@filename)
    sleep(1) #kind of cheesy, but guaranteed to work, and without mocking...
    FileUtils.touch(@filename)
    si.freshen.should be_true
  end

  it 'does not freshen unless the file is modified' do
    si = RightSupport::Services::ServiceInfoFile.new(@filename)
    si.freshen.should be_false
  end
end