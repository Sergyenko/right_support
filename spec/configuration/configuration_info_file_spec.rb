require 'spec_helper'

def create_config_file(config)
  filename = Tempfile.new('right_support').path
  File.open(filename, 'w') { |f| f.puts YAML.dump(config) }
  filename
end

describe RightSupport::Configuration::ConfigurationInfoFile do

  it 'freshens when the file is modified on disk' do
    filename = create_config_file({})
    config_obj = RightSupport::Configuration::ConfigurationInfoFile.new(filename, "development")
    sleep(1) #kind of cheesy, but guaranteed to work, and without mocking...
    FileUtils.touch(filename)
    config_obj.freshen.should be_true
  end

  it 'does not freshen unless the file is modified' do
    filename = create_config_file({})
    config_obj = RightSupport::Configuration::ConfigurationInfoFile.new(filename, "development")
    config_obj.freshen.should be_false
  end
  
  context "common section is present" do
    
    it "should use the value defined in the common section when environment doesn't specify it" do
      filename = create_config_file({
        "development" => {},
        "common"      => {
          "monkey" => 13
        }
      })
      
      config_obj = RightSupport::Configuration::ConfigurationInfoFile.new(filename, "development")
      config_obj[:monkey].should == 13
    end
    
    it "should not use the value from the common section if an environment specifies it" do
      filename = create_config_file({
        "development" => {
          "monkey" => 10
        },
        "common"      => {
          "monkey" => 13
        }
      })
      
      config_obj = RightSupport::Configuration::ConfigurationInfoFile.new(filename, "development")
      config_obj[:monkey].should == 10
    end
    
  end
  
  context "common section is not present" do
    
    it "should raise an error when environment is not found" do
      filename = create_config_file({
        "development" => {
          "monkey" => 13
        },
      })
      
      config_obj = RightSupport::Configuration::ConfigurationInfoFile.new(filename, "developmentfake")
      lambda {
        config_obj[:monkey]
      }.should raise_exception(RightSupport::Configuration::ConfigurationInfoFile::UnknownKey)
    end
    
    it "should raise an error when key is not found" do
      filename = create_config_file({
        "development" => {
          "monkeyfake" => 13
        },
      })
      
      config_obj = RightSupport::Configuration::ConfigurationInfoFile.new(filename, "development")
      lambda {
        config_obj[:monkey]
      }.should raise_exception(RightSupport::Configuration::ConfigurationInfoFile::UnknownKey)
    end
    
  end

  context "freshen callback" do
    
    it "should be called when the object is created and when the file is freshend" do
      filename = create_config_file({
        "development" => {
          "monkey" => 13
        }
      })
      callback_called = false
      
      # dummy callback to just test it being called
      config_obj = RightSupport::Configuration::ConfigurationInfoFile.new(filename, "development") do
        callback_called = true
      end
      
      callback_called.should == true
      callback_called = false
      
      sleep(1)
      FileUtils.touch(filename)
            
      # force a freshen to occur by reading a value
      config_obj[:monkey].should == 13
      
      callback_called.should == true
    end
    
    it "should allow for the modification of the data" do
      filename = create_config_file({
        "development" => {
          "monkey" => 13
        }
      })
      
      config_obj = RightSupport::Configuration::ConfigurationInfoFile.new(filename, "development") do |data|
        # notice use of strings since we are dealing with raw yaml, not the config interface
        data["monkey"] = data["monkey"] + 1
      end
      
      config_obj[:monkey].should == 14
    end
    
  end
end