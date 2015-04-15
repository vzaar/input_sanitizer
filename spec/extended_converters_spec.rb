require 'spec_helper'
require 'input_sanitizer/extended_converters'

describe InputSanitizer::AllowNil do
  it "passes blanks" do
    expect(lambda { |_| 1 }.extend(InputSanitizer::AllowNil).call("")).to be_nil
  end

  it "passes things the extended sanitizer passes" do
    expect(lambda { |_| :something }.extend(InputSanitizer::AllowNil).call(:stuff)).
      to eq(:something)
  end

  it "raises error if the extended sanitizer raises error" do
    action = lambda do
      lambda { |_| raise "Some error" }.extend(InputSanitizer::AllowNil).call(:stuff)
    end

    expect(action).to raise_error
  end
end

describe InputSanitizer::PositiveIntegerConverter do
  let(:converter) { InputSanitizer::PositiveIntegerConverter.new }

  it "raises error if integer less than zero" do
    expect { converter.call("-3") }.to raise_error(InputSanitizer::ConversionError)
  end

  it "raises error if integer equals zero" do
    expect { converter.call("0") }.to raise_error(InputSanitizer::ConversionError)
  end
end

describe InputSanitizer::CommaJoinedIntegersConverter do
  let(:converter) { InputSanitizer::CommaJoinedIntegersConverter.new }

  it "parses to array of ids" do
    expect(converter.call("1,2,3,5")).to eq([1, 2, 3, 5])
  end

  it "raises on invalid character" do
    expect { converter.call(":") }.to raise_error(InputSanitizer::ConversionError)
  end
end

describe InputSanitizer::CommaJoinedStringsConverter do
  let(:converter) { described_class.new }

  it "parses to array of ids" do
    expect(converter.call("input,Sanitizer,ROCKS")).to eq(["input", "Sanitizer", "ROCKS"])
  end

  it "raises on invalid character" do
    expect { converter.call(":") }.to raise_error(InputSanitizer::ConversionError)
  end
end

describe InputSanitizer::SpecificValuesConverter do
  let(:converter) { InputSanitizer::SpecificValuesConverter.new([:a, :b]) }

  it "converts valid value to symbol" do
    expect(converter.call("b")).to eq(:b)
  end

  it "raises on invalid value" do
    expect { converter.call("c") }.to raise_error(InputSanitizer::ConversionError)
  end

  it "converts valid value to string" do
    converter = InputSanitizer::SpecificValuesConverter.new(["a", "b"])
    expect(converter.call("a")).to eq("a")
  end
end
