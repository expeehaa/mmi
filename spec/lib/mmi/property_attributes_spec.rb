require 'mmi/property_attributes'

RSpec.describe Mmi::PropertyAttributes do
	let(:test_class) do
		Class.new do |klass|
			klass.prepend Mmi::PropertyAttributes
		end
	end
	let(:parsing_struct) do
		Struct.new(:a) do |s|
			s.define_singleton_method(:parse) do |hash|
				s.new(hash)
			end
		end
	end
	
	describe '#initialize' do
		it 'requires a parameter' do
			expect{test_class.new           }.    to raise_error ArgumentError, 'wrong number of arguments (given 0, expected 1)'
			expect{test_class.new({asdf: 5})}.not_to raise_error
		end
	end
	
	describe '#to_h' do
		it 'returns the #initialize parameter as a hash' do
			expect(test_class.new({asdf: 5}).to_h).to eq({asdf: 5})
		end
	end
	
	describe '#[]' do
		it 'returns the value of a given key in the hash' do
			expect(test_class.new({asdf: 5})[:asdf]).to eq 5
		end
	end
	
	describe '.registered_properties' do
		it 'returns an empty Hash' do
			expect(test_class.registered_properties).to eq({})
		end
		
		it 'always returns the same Hash instance' do
			test_class.registered_properties[:asdf] = :qwertz
			
			expect(test_class.registered_properties).to eq({asdf: :qwertz})
		end
	end
	
	describe '.property' do
		it 'defines a method named after the first argument' do
			expect(test_class.instance_methods).not_to include :test
			
			test_class.property(:test)
			
			expect(test_class.instance_methods).    to include :test
		end
		
		it 'registers a property with all given arguments or their defaults' do
			validation_proc = ->(a, b) { b << 'invalid' }
			
			test_class.property(:asdf, 'not asdf', type: parsing_struct, required: false, default: :blob, requires: [:nothing], conflicts: :anything, validate: validation_proc)
			test_class.property(:qwertz)
			
			expect(test_class.registered_properties).to eq(
				{
					asdf:   Mmi::PropertyAttributes::ClassMethods::PropertyConfiguration.new(key: 'not asdf', type: parsing_struct, required: false, default: :blob, requires: [:nothing], conflicts: [:anything], validate: validation_proc),
					qwertz: Mmi::PropertyAttributes::ClassMethods::PropertyConfiguration.new(key: 'qwertz',   type: nil,            required: true,  default: nil,   requires: [        ], conflicts: [         ], validate: nil            ),
				}
			)
		end
		
		it 'requires the first argument to be a Symbol' do
			expect{test_class.property('test')}.to raise_error ArgumentError, '"method_name" must be a Symbol'
		end
		
		it 'defaults the second positional argument to the stringified first argument' do
			test_class.property(:asdf)
			
			expect(test_class.registered_properties.fetch(:asdf).key).to eq 'asdf'
		end
		
		it 'allows only nil, an object responding to :new or a specific Hash as :type' do
			expect{test_class.property(:asdf,  type: 5             )}.    to raise_error ArgumentError, '5 is not a valid "type"'
			expect{test_class.property(:asdf,  type: '5'           )}.    to raise_error ArgumentError, '"5" is not a valid "type"'
			expect{test_class.property(:asdf0, type: nil           )}.not_to raise_error
			expect{test_class.property(:asdf1, type: parsing_struct)}.not_to raise_error
			
			expect{test_class.property(:asdf,  type: {}                                             )}.    to raise_error ArgumentError, '{} is not a valid "type"'
			expect{test_class.property(:asdf,  type: {field: '23'                                  })}.    to raise_error ArgumentError, '{field: "23"} is not a valid "type"'
			expect{test_class.property(:asdf,  type: {             types: {}                       })}.    to raise_error ArgumentError, '{types: {}} is not a valid "type"'
			expect{test_class.property(:asdf,  type: {field: '23', types: []                       })}.    to raise_error ArgumentError, '{field: "23", types: []} is not a valid "type"'
			expect{test_class.property(:asdf2, type: {field: '23', types: {}                       })}.not_to raise_error
			expect{test_class.property(:asdf,  type: {field: '23', types: {'cba' => 5             }})}.    to raise_error ArgumentError, '{field: "23", types: {"cba" => 5}} is not a valid "type"'
			expect{test_class.property(:asdf3, type: {field: '23', types: {'cba' => nil           }})}.not_to raise_error
			expect{test_class.property(:asdf4, type: {field: '23', types: {'cba' => parsing_struct}})}.not_to raise_error
		end
		
		it 'changes "requires" to an array if it is not' do
			test_class.property(:prop0, requires: 5  )
			test_class.property(:prop1, requires: [5])
			
			expect(test_class.registered_properties.fetch(:prop0).requires).to eq [5]
			expect(test_class.registered_properties.fetch(:prop1).requires).to eq [5]
		end
		
		it 'changes "conflicts" to an array if it is not' do
			test_class.property(:prop0, conflicts: 5  )
			test_class.property(:prop1, conflicts: [5])
			
			expect(test_class.registered_properties.fetch(:prop0).conflicts).to eq [5]
			expect(test_class.registered_properties.fetch(:prop1).conflicts).to eq [5]
		end
		
		it 'has parameter "required" true mutually exclusive with non-empty "requires" and "conflicts"' do
			expect{test_class.property(:asdf,  required: true,  requires: [:test]                    )}.    to raise_error ArgumentError, '"required" is mutually exclusive with "requires" and "conflicts"'
			expect{test_class.property(:asdf,  required: true,                     conflicts: [:qwer])}.    to raise_error ArgumentError, '"required" is mutually exclusive with "requires" and "conflicts"'
			expect{test_class.property(:asdf,  required: true,  requires: [:test], conflicts: [:qwer])}.    to raise_error ArgumentError, '"required" is mutually exclusive with "requires" and "conflicts"'
			expect{test_class.property(:asdf0, required: false, requires: [:test]                    )}.not_to raise_error
			expect{test_class.property(:asdf1, required: false,                    conflicts: [:qwer])}.not_to raise_error
			expect{test_class.property(:asdf2, required: false, requires: [:test], conflicts: [:qwer])}.not_to raise_error
			expect{test_class.property(:asdf3, required: true,  requires: [],      conflicts: []     )}.not_to raise_error
			expect{test_class.property(:asdf4, required: true                                        )}.not_to raise_error
		end
		
		it 'has parameter "required" true mutually exclusive with non-nil "default"' do
			expect{test_class.property(:asdf,  required: true,  default: 23 )}.    to raise_error ArgumentError, '"required" is mutually exclusive with "default"'
			expect{test_class.property(:asdf0, required: false, default: 23 )}.not_to raise_error
			expect{test_class.property(:asdf1, required: true,  default: nil)}.not_to raise_error
			expect{test_class.property(:asdf2, required: false, default: nil)}.not_to raise_error
		end
		
		it 'defaults "required" to true if "default", "requires" and "conflicts" are not given' do
			test_class.property(:asdf0                  )
			test_class.property(:asdf1, default:   :test)
			test_class.property(:asdf2, requires:  :test)
			test_class.property(:asdf3, conflicts: :test)
			
			expect(test_class.registered_properties[:asdf0].required).to be true
			expect(test_class.registered_properties[:asdf1].required).to be false
			expect(test_class.registered_properties[:asdf2].required).to be false
			expect(test_class.registered_properties[:asdf3].required).to be false
		end
		
		it 'does not allow shared entries in "requires" and "conflicts"' do
			expect{test_class.property(:asdf, requires: [:test       ], conflicts: [:test       ])}.    to raise_error ArgumentError, '"requires" and "conflicts" must not share entries'
			expect{test_class.property(:asdf, requires: [:asdf, :test], conflicts: [:test, :qwer])}.    to raise_error ArgumentError, '"requires" and "conflicts" must not share entries'
			expect{test_class.property(:asdf, requires: [:entry      ], conflicts: :entry        )}.    to raise_error ArgumentError, '"requires" and "conflicts" must not share entries'
			expect{test_class.property(:asdf, requires: [:entry      ], conflicts: :entry2       )}.not_to raise_error
		end
		
		it 'allows only nil, a Symbol or a Proc as "validate"' do
			expect{test_class.property(:asdf,  validate: 5    )}.    to raise_error ArgumentError, '"validate" must be nil, a symbol or a Proc'
			expect{test_class.property(:asdf,  validate: '5'  )}.    to raise_error ArgumentError, '"validate" must be nil, a symbol or a Proc'
			expect{test_class.property(:asdf,  validate: ['5'])}.    to raise_error ArgumentError, '"validate" must be nil, a symbol or a Proc'
			expect{test_class.property(:asdf0, validate: nil  )}.not_to raise_error
			expect{test_class.property(:asdf1, validate: :test)}.not_to raise_error
			expect{test_class.property(:asdf2, validate: ->{} )}.not_to raise_error
		end
	end
	
	describe '#validate_constraints!' do
		context 'without properties defined' do
			it 'returns true' do
				expect(test_class.new({}           ).validate_constraints!).to be true
				expect(test_class.new({asdf: :test}).validate_constraints!).to be true
			end
		end
		
		context 'with properties defined' do
			it 'checks the presence of "key" if "required" is true' do
				klass = Class.new do |k|
					k.prepend Mmi::PropertyAttributes
					
					k.property(:asdf, :asdf, required: true)
				end
				
				expect{klass.new({}                       ).validate_constraints!}.    to raise_error Mmi::PropertyAttributes::ValidationError, 'asdf: missing field asdf'
				expect{klass.new({asdf: 1234             }).validate_constraints!}.not_to raise_error
				expect{klass.new({asdf: 1234, 'test' => 0}).validate_constraints!}.not_to raise_error
			end
			
			it 'checks presence of "requires"' do
				klass = Class.new do |k|
					k.prepend Mmi::PropertyAttributes
					
					k.property(:asdf, :asdf, requires: 'test')
				end
				
				expect{klass.new({asdf: 1234             }).validate_constraints!}.    to raise_error Mmi::PropertyAttributes::ValidationError, 'asdf: missing required field(s) "test"'
				expect{klass.new({asdf: 1234, 'test' => 0}).validate_constraints!}.not_to raise_error
				expect{klass.new({}                       ).validate_constraints!}.not_to raise_error
			end
			
			it 'checks presence of "conflicts"' do
				klass = Class.new do |k|
					k.prepend Mmi::PropertyAttributes
					
					k.property(:asdf, :asdf, conflicts: 'test')
				end
				
				expect{klass.new({asdf: 1234, 'test' => 0}).validate_constraints!}.    to raise_error Mmi::PropertyAttributes::ValidationError, 'asdf: conflicting with field(s) "test"'
				expect{klass.new({asdf: 1234             }).validate_constraints!}.not_to raise_error
				expect{klass.new({}                       ).validate_constraints!}.not_to raise_error
			end
			
			it 'validates all properties' do
				klass = Class.new do |k|
					k.prepend Mmi::PropertyAttributes
					
					k.property(:qwer, :qwer, requires: 'abc'                   )
					k.property(:asdf, :asdf,                  conflicts: 'test')
					k.property(:pops, :pops, requires: 'abc', conflicts: 'test')
				end
				
				expect{klass.new({asdf: 1234, qwer: 12, pops: 'wq', 'test' => 'r'              }).validate_constraints!}.    to raise_error Mmi::PropertyAttributes::ValidationError, 'qwer: missing required field(s) "abc"; asdf: conflicting with field(s) "test"; pops: missing required field(s) "abc", conflicting with field(s) "test"'
				expect{klass.new({asdf: 1234, qwer: 12, pops: 'wq'                             }).validate_constraints!}.    to raise_error Mmi::PropertyAttributes::ValidationError, 'qwer: missing required field(s) "abc"; pops: missing required field(s) "abc"'
				expect{klass.new({asdf: 1234, qwer: 12, pops: 'wq',                'abc' => 'e'}).validate_constraints!}.not_to raise_error
				expect{klass.new({}                                                             ).validate_constraints!}.not_to raise_error
			end
			
			it 'checks the presence of a valid type selector field' do
				klass = Class.new do |k|
					k.prepend Mmi::PropertyAttributes
					
					k.property(:asdf, :asdf, type: {field: :a, types: {5 => nil, 'w' => nil}})
				end
				
				expect{klass.new({}              ).validate_constraints!}.    to raise_error Mmi::PropertyAttributes::ValidationError, 'asdf: missing field asdf'
				expect{klass.new({asdf: 5       }).validate_constraints!}.    to raise_error Mmi::PropertyAttributes::ValidationError, 'asdf: field :asdf must be a Hash'
				expect{klass.new({asdf: {a: 123}}).validate_constraints!}.    to raise_error Mmi::PropertyAttributes::ValidationError, 'asdf: field :asdf must have key :a with one of values 5, "w"'
				expect{klass.new({asdf: {a: 5  }}).validate_constraints!}.not_to raise_error
				expect{klass.new({asdf: {a: 'w'}}).validate_constraints!}.not_to raise_error
			end
			
			it 'calls the "validate" Proc or Proc-ified Symbol' do
				klass = Class.new do |k|
					k.prepend Mmi::PropertyAttributes
					
					k.property(:asdf, :asdf, required: false, validate: :some_validator                                                      )
					k.property(:qwer, :qwer, required: false, validate: ->(value, errors) { if value != 8 then errors << 'very invalid' end })
					
					k.define_singleton_method(:some_validator) do |value, errors|
						if value != 8
							errors << 'invalid'
						end
					end
				end
				
				expect{klass.new({asdf: 5         }).validate_constraints!}.    to raise_error Mmi::PropertyAttributes::ValidationError, 'asdf: invalid'
				expect{klass.new({asdf: 8         }).validate_constraints!}.not_to raise_error
				expect{klass.new({         qwer: 5}).validate_constraints!}.    to raise_error Mmi::PropertyAttributes::ValidationError, 'qwer: very invalid'
				expect{klass.new({         qwer: 8}).validate_constraints!}.not_to raise_error
				expect{klass.new({asdf: 5, qwer: 5}).validate_constraints!}.    to raise_error Mmi::PropertyAttributes::ValidationError, 'asdf: invalid; qwer: very invalid'
				expect{klass.new({asdf: 8, qwer: 5}).validate_constraints!}.    to raise_error Mmi::PropertyAttributes::ValidationError, 'qwer: very invalid'
				expect{klass.new({asdf: 8, qwer: 8}).validate_constraints!}.not_to raise_error
				expect{klass.new({}                ).validate_constraints!}.not_to raise_error
			end
		end
	end
	
	describe '#parsed_property_store' do
		let(:test_instance) { test_class.new({}) }
		
		it 'returns an empty Hash' do
			expect(test_instance.parsed_property_store).to eq({})
		end
		
		it 'always returns the same Hash instance' do
			test_instance.parsed_property_store[:asdf] = :qwertz
			
			expect(test_instance.parsed_property_store).to eq({asdf: :qwertz})
		end
	end
	
	describe '.parse' do
		it 'calls #parse! on a new instance of the class' do
			expect_any_instance_of(Mmi::PropertyAttributes).to receive(:parse!).once.and_return(8274)
			
			expect(test_class.parse({})).to eq 8274
		end
	end
	
	describe '#parse!' do
		it 'validates constraints' do
			expect_any_instance_of(Mmi::PropertyAttributes).to receive(:validate_constraints!).once
			
			test_class.new({}).parse!
		end
		
		it 'parses properties if necessary and stores them' do
			scopes_are_weird = parsing_struct
			klass            = Class.new do |k|
				k.prepend Mmi::PropertyAttributes
				
				k.property(:asdf,   'qwe', required: false, type: nil                                                )
				k.property(:zxcvbn, 'xc',  required: true,  type: scopes_are_weird                                   )
				k.property(:a,             required: false, type: {field: :name, types: {'hjkl' => scopes_are_weird}})
			end
			
			expect(klass.new({'qwe' => 5213, 'xc' => 'test'                                 }).parse!.parsed_property_store).to eq({asdf: 5213, zxcvbn: parsing_struct.new('test')                                                 })
			expect(klass.new({               'xc' => 'test', 'a' => {name: 'hjkl', ikl: 283}}).parse!.parsed_property_store).to eq({            zxcvbn: parsing_struct.new('test'), a: parsing_struct.new({name: 'hjkl', ikl: 283})})
			expect(klass.new({'qwe' => 5213, 'xc' => 'test', 'a' => {name: 'hjkl', ikl: 283}}).parse!.parsed_property_store).to eq({asdf: 5213, zxcvbn: parsing_struct.new('test'), a: parsing_struct.new({name: 'hjkl', ikl: 283})})
		end
	end
	
	describe 'property methods' do
		it 'returns the parsed property' do
			scopes_are_weird         = parsing_struct
			propertied_test_instance = Class.new do |klass|
				klass.prepend Mmi::PropertyAttributes
				
				klass.property(:asdf, type: scopes_are_weird)
			end.parse({'asdf' => 10954})
			
			expect(propertied_test_instance.asdf).to eq parsing_struct.new(10954)
			
			propertied_test_instance.parsed_property_store[:asdf] = 'i like trains'
			
			expect(propertied_test_instance.asdf).to eq 'i like trains'
		end
	end
	
	describe '#update_properties!' do
		it 'requires a Hash argument' do
			expect{test_class.new({}).update_properties!    }.    to raise_error ArgumentError, 'wrong number of arguments (given 0, expected 1)'
			expect{test_class.new({}).update_properties!(5 )}.    to raise_error ArgumentError, 'argument must be a Hash'
			expect{test_class.new({}).update_properties!({})}.not_to raise_error
		end
		
		it 'sets a property and validates and parses the value' do
			klass = Class.new do |k|
				k.prepend Mmi::PropertyAttributes
				
				k.property(:asdf, required: false, validate: ->(value, errors) { if value != 3 then errors << 'invalid' end })
			end
			
			expect{klass.new({})                              }.not_to raise_error
			expect{klass.new({}).update_properties!({qwer: 4})}.    to raise_error ArgumentError, 'argument can only have keys that are defined properties'
			expect{klass.new({}).update_properties!({asdf: 4})}.    to raise_error Mmi::PropertyAttributes::ValidationError, 'asdf: invalid'
			
			klass.new({}).update_properties!({asdf: 3}).tap do |instance|
				expect(instance.asdf).to eq 3
				expect(instance.to_h).to eq({'asdf' => 3})
			end
		end
		
		it 'sets multiple properties at once' do
			klass = Class.new do |k|
				k.prepend Mmi::PropertyAttributes
				
				k.property(:asdf, required: false, validate: ->(value, errors) { if value != 3 then errors << 'invalid'      end })
				k.property(:hjkl, required: false, validate: ->(value, errors) { if value == 5 then errors << 'also invalid' end })
			end
			
			klass.new({}).update_properties!({asdf: 3, hjkl: 2578}).tap do |instance|
				expect(instance.asdf).to eq 3
				expect(instance.hjkl).to eq 2578
				expect(instance.to_h).to eq({'asdf' => 3, 'hjkl' => 2578})
			end
		end
		
		it 'restores previous parsed properties and values if validation fails' do
			klass = Class.new do |k|
				k.prepend Mmi::PropertyAttributes
				
				k.property(:asdf, validate: ->(value, errors) { if value != 3 then errors << 'invalid' end })
			end
			
			instance = klass.parse({'asdf' => 3})
			
			expect(instance.asdf).to eq 3
			expect(instance.to_h).to eq({'asdf' => 3})
			
			expect{instance.update_properties!({asdf: 4})}.to raise_error Mmi::PropertyAttributes::ValidationError, 'asdf: invalid'
			
			expect(instance.asdf).to eq 3
			expect(instance.to_h).to eq({'asdf' => 3})
		end
	end
end
