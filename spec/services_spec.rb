require 'spec_helper'

describe RightSupport::Services do
  before(:each) do
    @filename = Tempfile.new('right_support').path
    @settings = { 'awesome' => {'class' => 'StubAwesomeService',
                                'settings' =>
                                    {'endpoints' => [1, 2, 3], 'cuckoo' => 'clock'}
                                }
                }
  end

  it 're-creates service proxies whenever their ServiceInfos have been freshened' do
    File.open(@filename, 'w') { |f| f.puts YAML.dump(@settings) }
    RightSupport::Services.register(RightSupport::Services::ServiceInfo.from_file(@filename))
    s1 = RightSupport::Services.awesome
    sleep(1)
    FileUtils.touch(@filename)
    s2 = RightSupport::Services.awesome
    s1.object_id.should_not == s2.object_id
  end

  context 'with top-level class names' do
    before(:each) do
      @settings['awesome']['class'] = 'UselessNamespace::AliasedAwesomeService'
      File.open(@filename, 'w') { |f| f.puts YAML.dump(@settings) }
      RightSupport::Services.register(RightSupport::Services::ServiceInfo.from_file(@filename))
    end

    after(:each) do
      RightSupport::Services.reset
    end

    it 'allows access to service proxies' do
      service = RightSupport::Services.awesome
      service.is_a?(StubAwesomeService).should be_true
    end
  end

  context 'with namespaced class names' do
    before(:each) do
      File.open(@filename, 'w') { |f| f.puts YAML.dump(@settings) }
      RightSupport::Services.register(RightSupport::Services::ServiceInfo.from_file(@filename))
    end

    after(:each) do
      RightSupport::Services.reset
    end

    it 'allows access to service proxies' do
      service = RightSupport::Services.awesome
      service.is_a?(UselessNamespace::AliasedAwesomeService).should be_true
    end
  end
end