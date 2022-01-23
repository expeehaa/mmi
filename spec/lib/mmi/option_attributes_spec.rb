RSpec.describe Mmi::OptionAttributes do
	let(:test_class   ) do
		Class.new do
			include Mmi::OptionAttributes
			
			def initialize(options=nil)
				@options = options
			end
		end
	end
	let(:test_instance_without_options      ) { test_class.new                                      }
	let(:test_instance_with_non_hash_options) { test_class.new(5                                  ) }
	let(:test_instance_with_hash_options    ) { test_class.new({'asdf' => 10, 'donkey' => 'ee ah'}) }
	
	context 'with a class including it' do
		it 'extends the class' do
			expect(test_class.ancestors).to include(Mmi::OptionAttributes::ClassMethods)
		end
		
		it 'can be initialized' do
			expect{test_instance_without_options      }.not_to raise_error
			expect{test_instance_with_non_hash_options}.not_to raise_error
			expect{test_instance_with_hash_options    }.not_to raise_error
		end
	end
	
	describe '#options' do
		it 'returns the corresponding instance variable' do
			expect(test_instance_with_non_hash_options.options).to eq 5
			expect(test_instance_with_hash_options    .options).to eq({'asdf' => 10, 'donkey' => 'ee ah'})
			expect(test_instance_without_options      .options).to eq nil
			
			test_instance_without_options.instance_variable_set(:@options, :some_test_symbol)
			
			expect(test_instance_without_options      .options).to eq :some_test_symbol
		end
		
		it 'cannot be set' do
			expect{test_instance_without_options.options = :some_other_test_symbol}.to raise_error NoMethodError, %r{#{Regexp.escape(%q(undefined method `options=' for ))}}
		end
	end
	
	describe '.opt_writer' do
		before do
			test_class.opt_writer(:test_1          )
			test_class.opt_writer('test_2'         )
			test_class.opt_writer(:test_3, 'cow'   )
			test_class.opt_writer(:test_4, 'donkey')
		end
		
		it 'defines a writer on the class' do
			expect(test_instance_with_hash_options).    to respond_to(:test_1=)
			expect(test_instance_with_hash_options).not_to respond_to(:test_1 )
			expect(test_instance_with_hash_options).    to respond_to(:test_2=)
			expect(test_instance_with_hash_options).not_to respond_to(:test_2 )
			expect(test_instance_with_hash_options).    to respond_to(:test_3=)
			expect(test_instance_with_hash_options).not_to respond_to(:test_3 )
			expect(test_instance_with_hash_options).    to respond_to(:test_4=)
			expect(test_instance_with_hash_options).not_to respond_to(:test_4 )
		end
		
		describe 'the writer method' do
			it 'fails if options is not a hash' do
				expect{test_instance_without_options      .test_1 = 'goat'}.to raise_error NoMethodError, %r{#{Regexp.escape(%q(undefined method `[]=' for nil:NilClass))}}
				expect{test_instance_with_non_hash_options.test_1 = 'goat'}.to raise_error NoMethodError, %r{#{Regexp.escape(%q(undefined method `[]=' for 5:Integer)   )}}
				expect{test_instance_without_options      .test_2 = 'goat'}.to raise_error NoMethodError, %r{#{Regexp.escape(%q(undefined method `[]=' for nil:NilClass))}}
				expect{test_instance_with_non_hash_options.test_2 = 'goat'}.to raise_error NoMethodError, %r{#{Regexp.escape(%q(undefined method `[]=' for 5:Integer)   )}}
				expect{test_instance_without_options      .test_3 = 'goat'}.to raise_error NoMethodError, %r{#{Regexp.escape(%q(undefined method `[]=' for nil:NilClass))}}
				expect{test_instance_with_non_hash_options.test_3 = 'goat'}.to raise_error NoMethodError, %r{#{Regexp.escape(%q(undefined method `[]=' for 5:Integer)   )}}
				expect{test_instance_without_options      .test_4 = 'goat'}.to raise_error NoMethodError, %r{#{Regexp.escape(%q(undefined method `[]=' for nil:NilClass))}}
				expect{test_instance_with_non_hash_options.test_4 = 'goat'}.to raise_error NoMethodError, %r{#{Regexp.escape(%q(undefined method `[]=' for 5:Integer)   )}}
			end
			
			it 'sets a value in the options hash with writer #test_1=' do
				expect{test_instance_with_hash_options.test_1 = 'goat'}.to change{test_instance_with_hash_options.options}.from({'asdf' => 10, 'donkey' => 'ee ah'}).to({'asdf' => 10, 'donkey' => 'ee ah', 'test_1' => 'goat'})
			end
			
			it 'sets a value in the options hash with writer #test_2=' do
				expect{test_instance_with_hash_options.test_2 = 'goat'}.to change{test_instance_with_hash_options.options}.from({'asdf' => 10, 'donkey' => 'ee ah'}).to({'asdf' => 10, 'donkey' => 'ee ah', 'test_2' => 'goat'})
			end
			
			it 'sets a value in the options hash with writer #test_3=' do
				expect{test_instance_with_hash_options.test_3 = 'goat'}.to change{test_instance_with_hash_options.options}.from({'asdf' => 10, 'donkey' => 'ee ah'}).to({'asdf' => 10, 'donkey' => 'ee ah', 'cow' => 'goat'})
			end
			
			it 'sets a value in the options hash with writer #test_4=' do
				expect{test_instance_with_hash_options.test_4 = 'goat'}.to change{test_instance_with_hash_options.options}.from({'asdf' => 10, 'donkey' => 'ee ah'}).to({'asdf' => 10, 'donkey' => 'goat'})
			end
			
			it 'deletes the key-value pair in the options hash when setting nil' do
				expect{test_instance_with_hash_options.test_1 = nil}.not_to(change{test_instance_with_hash_options.options})
				expect{test_instance_with_hash_options.test_2 = nil}.not_to(change{test_instance_with_hash_options.options})
				expect{test_instance_with_hash_options.test_3 = nil}.not_to(change{test_instance_with_hash_options.options})
				expect{test_instance_with_hash_options.test_4 = nil}.    to change{test_instance_with_hash_options.options}.from({'asdf' => 10, 'donkey' => 'ee ah'}).to({'asdf' => 10})
			end
		end
	end
	
	describe '.opt_reader' do
		before do
			test_class.opt_reader(:test_1          ) { 8 }
			test_class.opt_reader('test_2'         )
			test_class.opt_reader(:test_3, 'cow'   )
			test_class.opt_reader(:test_4, 'donkey')
		end
		
		it 'defines a reader on the class' do
			expect(test_instance_with_hash_options).    to respond_to(:test_1 )
			expect(test_instance_with_hash_options).not_to respond_to(:test_1=)
			expect(test_instance_with_hash_options).    to respond_to(:test_2 )
			expect(test_instance_with_hash_options).not_to respond_to(:test_2=)
			expect(test_instance_with_hash_options).    to respond_to(:test_3 )
			expect(test_instance_with_hash_options).not_to respond_to(:test_3=)
			expect(test_instance_with_hash_options).    to respond_to(:test_4 )
			expect(test_instance_with_hash_options).not_to respond_to(:test_4=)
		end
		
		describe 'the reader method' do
			it 'fails if options is not a hash' do
				expect{test_instance_without_options      .test_1}.to raise_error NoMethodError, %r{#{Regexp.escape(%q(undefined method `[]' for nil:NilClass)       )}}
				expect{test_instance_with_non_hash_options.test_1}.to raise_error TypeError,     %r{#{Regexp.escape(%q(no implicit conversion of String into Integer))}}
				expect{test_instance_without_options      .test_2}.to raise_error NoMethodError, %r{#{Regexp.escape(%q(undefined method `[]' for nil:NilClass)       )}}
				expect{test_instance_with_non_hash_options.test_2}.to raise_error TypeError,     %r{#{Regexp.escape(%q(no implicit conversion of String into Integer))}}
				expect{test_instance_without_options      .test_3}.to raise_error NoMethodError, %r{#{Regexp.escape(%q(undefined method `[]' for nil:NilClass)       )}}
				expect{test_instance_with_non_hash_options.test_3}.to raise_error TypeError,     %r{#{Regexp.escape(%q(no implicit conversion of String into Integer))}}
				expect{test_instance_without_options      .test_4}.to raise_error NoMethodError, %r{#{Regexp.escape(%q(undefined method `[]' for nil:NilClass)       )}}
				expect{test_instance_with_non_hash_options.test_4}.to raise_error TypeError,     %r{#{Regexp.escape(%q(no implicit conversion of String into Integer))}}
			end
			
			it 'gets the correct value' do
				expect(test_instance_with_hash_options.test_1).to eq 8
				expect(test_instance_with_hash_options.test_2).to eq nil
				expect(test_instance_with_hash_options.test_3).to eq nil
				expect(test_instance_with_hash_options.test_4).to eq 'ee ah'
			end
		end
	end
	
	describe '.opt_accessor' do
		it 'calls .opt_reader and .opt_writer' do
			RSpec::Mocks.with_temporary_scope do
				expect(test_class).to receive(:opt_reader).with(:test_1, 'test_1').once do |&block|
					expect(block).to eq nil
				end
				expect(test_class).to receive(:opt_writer).with(:test_1, 'test_1').once do |&block|
					expect(block).to eq nil
				end
				
				test_class.opt_accessor(:test_1)
			end
			
			RSpec::Mocks.with_temporary_scope do
				expect(test_class).to receive(:opt_reader).with(:test_2, :donkey).once do |&block|
					expect(block).to eq nil
				end
				expect(test_class).to receive(:opt_writer).with(:test_2, :donkey).once do |&block|
					expect(block).to eq nil
				end
				
				test_class.opt_accessor(:test_2, :donkey)
			end
			
			RSpec::Mocks.with_temporary_scope do
				expect(test_class).to receive(:opt_reader).with(:test_3, 'test_3').once do |&block|
					expect(block.call).to eq 2
				end
				expect(test_class).to receive(:opt_writer).with(:test_3, 'test_3').once do |&block|
					expect(block).to eq nil
				end
				
				test_class.opt_accessor(:test_3) do
					2
				end
			end
		end
	end
end
