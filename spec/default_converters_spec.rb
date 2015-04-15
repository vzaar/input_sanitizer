require 'spec_helper'

describe InputSanitizer::IntegerConverter do
  let(:converter) { InputSanitizer::IntegerConverter.new }

  it "casts string to integer" do
    expect(converter.call("42")).to eq(42)
  end

  it "casts integer to integer" do
    expect(converter.call(42)).to eq(42)
  end

  it "raises error if cannot cast" do
    expect { converter.call("f") }.to raise_error(InputSanitizer::ConversionError)
  end
end

describe InputSanitizer::FloatConverter do
  let(:converter) { InputSanitizer::FloatConverter.new }

  it "casts string to float" do
    expect(converter.call("42")).to eq(42)
  end

  it "casts integer to float" do
    expect(converter.call(42)).to eq(42)
  end

  it "casts float to float" do
    expect(converter.call(42.12)).to eq(42.12)
  end

  it "raises error if cannot cast" do
    expect { converter.call("f") }.to raise_error(InputSanitizer::ConversionError)
  end
end

describe InputSanitizer::DateConverter do
  let(:converter) { InputSanitizer::DateConverter.new }

  it "casts dates in iso format" do
    expect(converter.call("2012-05-15")).to eq(Date.new(2012, 5, 15))
  end

  it "raises error if cannot cast" do
    expect { converter.call("2012-02-30") }.to raise_error(InputSanitizer::ConversionError)
  end
end

describe InputSanitizer::BooleanConverter do
  let(:converter) { InputSanitizer::BooleanConverter.new }

  it "casts 'true' to true" do
    expect(converter.call('true')).to be_truthy
  end

  it "casts 'True' to true" do
    expect(converter.call('True')).to be_truthy
  end

  it "casts true to true" do
    expect(converter.call(true)).to be_truthy
  end

  it "casts '1' to true" do
    expect(converter.call('1')).to be_truthy
  end

  it "casts 'yes' to true" do
    expect(converter.call('yes')).to be_truthy
  end

  it "casts 'false' to false" do
    expect(converter.call('false')).to be_falsey
  end

  it "casts 'False' to false" do
    expect(converter.call('False')).to be_falsey
  end

  it "casts false to false" do
    expect(converter.call(false)).to be_falsey
  end

  it "casts '0' to false" do
    expect(converter.call('0')).to be_falsey
  end

  it "casts 'no' to false" do
    expect(converter.call('no')).to be_falsey
  end

  it "raises error if cannot cast" do
    expect { converter.call("notboolean") }.to raise_error(InputSanitizer::ConversionError)
  end
end


describe InputSanitizer::TimeConverter do
  let(:converter) { InputSanitizer::TimeConverter.new }

  it "raises if timezone part given" do
    expect { converter.call("2012-05-15 13:42:54 +01:00") }.to raise_error(InputSanitizer::ConversionError)
  end

  it "casts date time in iso format" do
    t = Time.utc(2012, 5, 15, 13, 42, 54)
    expect(converter.call("2012-05-15 13:42:54")).to eq(t)
    expect(converter.call("2012-05-15T13:42:54")).to eq(t)
    expect(converter.call("20120515134254")).to eq(t)
  end

  it "works with miliseconds" do
    t = Time.utc(2012, 5, 15, 13, 42, 54)
    expect(converter.call("2012-05-15 13:42:54.000")).to eq(t)
    expect(converter.call("2012-05-15T13:42:54.000")).to eq(t)
    expect(converter.call("20120515134254000")).to eq(t)
  end

  it "works with Z at the end" do
    t = Time.utc(2012, 5, 15, 13, 42, 54)
    expect(converter.call("2012-05-15 13:42:54.000Z")).to eq(t)
    expect(converter.call("2012-05-15T13:42:54.000Z")).to eq(t)
   expect(converter.call("2012-05-15T13:42:54Z")).to eq(t)
    expect(converter.call("20120515134254000Z")).to eq(t)
  end

  it "does not require time part" do
    expect(converter.call("2012-05-15 13:42")).to eq(Time.utc(2012, 5, 15, 13, 42))
    expect(converter.call("2012-05-15 13")).to eq(Time.utc(2012, 5, 15, 13))
    expect(converter.call("2012-05-15")).to eq(Time.utc(2012, 5, 15))
  end

  it "raises error if can format is wrong" do
    expect { converter.call("2/10/2031 13:44:22") }.to raise_error(InputSanitizer::ConversionError)
  end

  it "raises error if date is wrong" do
    expect { converter.call("2012-02-32") }.to raise_error(InputSanitizer::ConversionError)
  end

  it "allows the instance of Time" do
    t = Time.now
    expect(converter.call(t)).to eq(t.utc)
  end
end
