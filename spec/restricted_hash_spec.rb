require "spec_helper"

describe InputSanitizer::RestrictedHash do
  let(:hash) { InputSanitizer::RestrictedHash.new([:a, :b]) }
  subject { hash }

  it "does not allow bad keys" do
    expect{hash[:c]}.to raise_error(InputSanitizer::KeyNotAllowedError)
  end

  it "does allow correct keys" do
    expect(hash[:a]).to be_nil
  end

  it "returns value for correct key" do
    hash[:a] = 'stuff'
    expect(hash[:a]).to eq('stuff')
  end
end
