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

  it 'freshens when the file is modified on disk'
end