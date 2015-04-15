require 'spec_helper'
require 'pry'

class NestedSanitizer < InputSanitizer::Sanitizer
  integer :foo
end

class NestedSanitizer2 < InputSanitizer::Sanitizer
  integer :bar, :required => true
end

class BasicSanitizer < InputSanitizer::Sanitizer
  string :x, :y, :z
  integer :namespaced, :namespace => :value
  integer :array, :collection => true
  integer :namespaced_array, :collection => true, :namespace => :value
  integer :num
  integer :profile, :as => :size_id
  date :birthday
  time :updated_at
  custom :cust1, :cust2, :converter => lambda { |v, s| v.reverse }
  custom :my_field, :converter => lambda { |v, s| v }, :as => :myfield
  nested :stuff, :sanitizer => NestedSanitizer, :collection => true, :namespace => :nested
  nested :stuff2, :sanitizer => NestedSanitizer2, :include_errors => true
end

class BrokenCustomSanitizer < InputSanitizer::Sanitizer

end

class ExtendedSanitizer < BasicSanitizer
  boolean :is_nice
end

class OverridingSanitizer < BasicSanitizer
  integer :is_nice
end

class RequiredParameters < BasicSanitizer
  integer :is_nice, :required => true
end

class RequiredCustom < BasicSanitizer
  custom :c1, :required => true, :converter => lambda { |v, s| v }
end

class DefaultParameters < BasicSanitizer
  integer :funky_number, :default => 5
  custom :fixed_stuff, :converter => lambda {|v, s| v }, :default => "default string"
end

describe InputSanitizer::Sanitizer do
  let(:sanitizer) { BasicSanitizer.new(@params) }

  describe ".clean" do
    it "returns cleaned data" do
      clean_data = double
      expect_any_instance_of(BasicSanitizer).to receive(:cleaned).and_return(clean_data)
      expect(BasicSanitizer.clean({})).to be(clean_data)
    end
  end

  describe "#cleaned" do
    let(:cleaned) { sanitizer.cleaned }
    let(:required) { RequiredParameters.new(@params) }

    context "freezing the hash" do
      it "freezes cleaned hash" do
        @params = {}
        expect(cleaned).to be_frozen
      end

      context "when freezing is disabled" do
        let(:sanitizer) do
          BasicSanitizer.new(@params, :freeze_output => false)
        end

        specify do
          @params = {}
          expect(cleaned).not_to be_frozen
        end
      end
    end

    it "includes specified params" do
      @params = {"x" => 3, "y" => "tom", "z" => "mike"}

      expect(cleaned).to have_key(:x)
      expect(cleaned).to have_key(:y)
      expect(cleaned).to have_key(:z)
    end

    it "strips not specified params" do
      @params = {"d" => 3}

      expect(cleaned).not_to have_key(:d)
    end

    it "uses RestrictedHash" do
      @params = {}

      expect{cleaned[:does_not_exist]}.to raise_error(InputSanitizer::KeyNotAllowedError)
    end

    it "includes specified keys and strips rest" do
      @params = {"d" => 3, "x" => "ddd"}

      expect(cleaned).to have_key(:x)
      expect(cleaned).not_to have_key(:d)
    end

    it "works with symbols as input keys" do
      @params = {:d => 3, :x => "ddd"}

      expect(cleaned).to have_key(:x)
      expect(cleaned).not_to have_key(:d)
    end

    it "preserves namespace" do
      value = { :value => 5 }
      @params = { :namespaced => value }

      expect(cleaned[:namespaced]).to eq(value)
    end

    it "maps values for collection fields" do
      numbers = [3, 5, 6]
      @params = { :array => numbers }

      expect(cleaned[:array]).to eq(numbers)
    end

    it "maps values for collection fields with namespace" do
      numbers = [
        { :value => 2 },
        { :value => 5 }
      ]
      @params = { :namespaced_array => numbers }

      expect(cleaned[:namespaced_array]).to eq(numbers)
    end

    it "silently discards cast errors" do
      @params = {:num => "f"}

      expect(cleaned).not_to have_key(:num)
    end

    it "inherits converters from superclass" do
      sanitizer = ExtendedSanitizer.new({:num => "23", :is_nice => 'false'})
      cleaned = sanitizer.cleaned

      expect(cleaned).to have_key(:num)
      expect(cleaned[:num]).to eq(23)
      expect(cleaned[:is_nice]).to be_falsey
    end

    it "overrides inherited fields" do
      sanitizer = OverridingSanitizer.new({:is_nice => "42"})
      cleaned = sanitizer.cleaned

      expect(cleaned).to have_key(:is_nice)
      expect(cleaned[:is_nice]).to eq(42)
    end


    describe "aliases" do
      context "when value exists" do
        before { @params = { :profile => 10, :my_field => 1 } }
        specify { expect(cleaned).to have_key(:size_id) }
        specify { expect(cleaned).to have_key(:myfield) }
      end

      context "when key doesn't exist" do
        before { @params = {} }
        specify do
          expect do
            cleaned[:size_id]
          end.not_to raise_error
        end
      end
    end


    context "when sanitizer is initialized with default values" do
      context "when paremeters are not overwriten" do
        let(:sanitizer) { DefaultParameters.new({}) }

        it "returns default value for non custom key" do
          expect(sanitizer.cleaned[:funky_number]).to eq(5)
        end

        it "returns default value for custom key" do
          expect(sanitizer.cleaned[:fixed_stuff]).to eq("default string")
        end
      end

      context "when parameters are overwriten" do
        let(:sanitizer) { DefaultParameters.new({ :funky_number => 2, :fixed_stuff => "fixed" }) }

        it "returns default value for non custom key" do
          expect(sanitizer.cleaned[:funky_number]).to eq(2)
        end

        it "returns default value for custom key" do
          expect(sanitizer.cleaned[:fixed_stuff]).to eq("fixed")
        end
      end
    end

  end

  describe ".custom" do
    let(:sanitizer) { BasicSanitizer.new(@params) }
    let(:cleaned) { sanitizer.cleaned }

    it "converts using custom converter" do
      @params = {:cust1 => "cigam"}

      expect(cleaned).to have_key(:cust1)
      expect(cleaned[:cust1]).to eq("magic")
    end

    it "raises an error when converter is not defined" do
      expect do
        BrokenCustomSanitizer.custom(:x)
      end.to raise_error
    end
  end

  describe ".nested" do
    let(:sanitizer) { BasicSanitizer.new(@params) }
    let(:cleaned) { sanitizer.cleaned }

    it "sanitizes nested values" do
      nested = [
        { :nested => { :foo => "5" } },
        { :nested => { :foo => 8 } },
      ]
      @params = { :stuff => nested }

      expected = [
        { :nested => { :foo => 5 } },
        { :nested => { :foo => 8 } },
      ]
      expect(cleaned[:stuff]).to eq(expected)
    end

    context "with errors enabled" do
      before do
        @params = { :stuff2 => { :foo => 10 } }
        cleaned
      end

      it "adds errors from nested sanitizer to parent" do
        err = sanitizer.errors.first

        expect(err[:field]).to eq(:bar)
        expect(err[:type]).to eq(:missing)
      end
    end
  end

  describe ".converters" do
    let(:sanitizer) { InputSanitizer::Sanitizer }

    it "includes :integer type" do
      expect(sanitizer.converters).to have_key(:integer)
      expect(sanitizer.converters[:integer]).to be_a(InputSanitizer::IntegerConverter)
    end

    it "includes :string type" do
      expect(sanitizer.converters).to have_key(:string)
      expect(sanitizer.converters[:string]).to be_a(InputSanitizer::StringConverter)
    end

    it "includes :date type" do
      expect(sanitizer.converters).to have_key(:date)
      expect(sanitizer.converters[:date]).to be_a(InputSanitizer::DateConverter)
    end

    it "includes :boolean type" do
      expect(sanitizer.converters).to have_key(:boolean)
      expect(sanitizer.converters[:boolean]).to be_a(InputSanitizer::BooleanConverter)
    end
  end

  describe '.extract_options' do

    it "extracts hash from array if is last" do
      options = { :a => 1}
      array = [1,2, options]
      expect(BasicSanitizer.extract_options(array)).to eq(options)
      expect(array).to eq([1,2, options])
    end

    it "does not extract the last element if not a hash and returns default empty hash" do
      array = [1,2]
      expect(BasicSanitizer.extract_options(array)).not_to eq(2)
      expect(BasicSanitizer.extract_options(array)).to eq({})
      expect(array).to eq([1,2])
    end

  end

  describe '.extract_options!' do

    it "extracts hash from array if is last" do
      options = { :a => 1}
      array = [1,2, options]
      expect(BasicSanitizer.extract_options!(array)).to eq(options)
      expect(array).to eq([1,2])
    end

    it "leaves other arrays alone" do
      array = [1,2]
      expect(BasicSanitizer.extract_options!(array)).to eq({})
      expect(array).to eq([1,2])
    end

  end

  describe "#valid?" do
    it "is valid when params are ok" do
      @params = {:num => "3"}

      expect(sanitizer).to be_valid
    end

    it "is not valid when missing params" do
      @params = {:num => "mike"}

      expect(sanitizer).not_to be_valid
    end
  end

  describe "#[]" do
    it "accesses cleaned data" do
      @params = {:num => "3"}

      expect(sanitizer[:num]).to eq(3)
    end
  end

  describe "#errors" do
    it "returns array containing hashes describing error" do
      @params = {:num => "mike"}

      errors = sanitizer.errors
      expect(errors.size).to eq(1)
      expect(errors[0][:field]).to eq(:num)
      expect(errors[0][:type]).to eq(:invalid_value)
      expect(errors[0][:description]).to eq("invalid integer")
      expect(errors[0][:value]).to eq("mike")
    end

    it "returns error type missing if value is missing" do
      sanitizer = RequiredParameters.new({})
      error = sanitizer.errors[0]
      expect(error[:type]).to eq(:missing)
    end

    it "handles required custom params" do
      sanitizer = RequiredCustom.new({})

      expect(sanitizer).not_to be_valid
      error = sanitizer.errors[0]
      expect(error[:type]).to eq(:missing)
      expect(error[:field]).to eq(:c1)
    end
  end
end
