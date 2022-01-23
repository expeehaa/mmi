RSpec.describe Mmi::Semver do
	describe '.new' do
		it 'can be initialized' do
			Mmi::Semver.new(1, 2, 3).tap do |v|
				expect(v.major).to eq 1
				expect(v.minor).to eq 2
				expect(v.patch).to eq 3
			end
		end
		
		it 'has no default values for parameters' do
			expect{Mmi::Semver.new(    )}.to raise_error ArgumentError, %r{#{Regexp.escape('wrong number of arguments (given 0, expected 3)')}}
			expect{Mmi::Semver.new(1   )}.to raise_error ArgumentError, %r{#{Regexp.escape('wrong number of arguments (given 1, expected 3)')}}
			expect{Mmi::Semver.new(1, 2)}.to raise_error ArgumentError, %r{#{Regexp.escape('wrong number of arguments (given 2, expected 3)')}}
		end
	end
	
	describe '.parse' do
		it 'takes an argument that responds to #strip' do
			expect{Mmi::Semver.parse(1 )}.    to raise_error NoMethodError, %r{#{Regexp.escape(%q{undefined method `strip' for 1:Integer})}}
			expect{Mmi::Semver.parse([])}.    to raise_error NoMethodError, %r{#{Regexp.escape(%q{undefined method `strip' for []:Array})}}
		end
		
		it 'requires the string to match a regex' do
			expect{Mmi::Semver.parse(''        )}.to raise_error RuntimeError, 'Version string not in valid format: ""'
			expect{Mmi::Semver.parse('test'    )}.to raise_error RuntimeError, 'Version string not in valid format: "test"'
			expect{Mmi::Semver.parse('1'       )}.to raise_error RuntimeError, 'Version string not in valid format: "1"'
			expect{Mmi::Semver.parse('1.'      )}.to raise_error RuntimeError, 'Version string not in valid format: "1."'
			expect{Mmi::Semver.parse('1.test'  )}.to raise_error RuntimeError, 'Version string not in valid format: "1.test"'
			expect{Mmi::Semver.parse('1.2'     )}.to raise_error RuntimeError, 'Version string not in valid format: "1.2"'
			expect{Mmi::Semver.parse('1.2.'    )}.to raise_error RuntimeError, 'Version string not in valid format: "1.2."'
			expect{Mmi::Semver.parse('1.2.test')}.to raise_error RuntimeError, 'Version string not in valid format: "1.2.test"'
			expect{Mmi::Semver.parse('1.2.3.'  )}.to raise_error RuntimeError, 'Version string not in valid format: "1.2.3."'
			expect{Mmi::Semver.parse('.1.2.3'  )}.to raise_error RuntimeError, 'Version string not in valid format: ".1.2.3"'
			expect{Mmi::Semver.parse('t1.2.3'  )}.to raise_error RuntimeError, 'Version string not in valid format: "t1.2.3"'
			expect{Mmi::Semver.parse('1.2.3t'  )}.to raise_error RuntimeError, 'Version string not in valid format: "1.2.3t"'
			
			expect{Mmi::Semver.parse('1.2.3')}.not_to raise_error
		end
		
		it 'parses a version string correctly' do
			Mmi::Semver.parse('1.0.0'    ).tap do |v|
				expect(v.major).to eq 1
				expect(v.minor).to eq 0
				expect(v.patch).to eq 0
			end
			Mmi::Semver.parse('1.2.0'  ).tap do |v|
				expect(v.major).to eq 1
				expect(v.minor).to eq 2
				expect(v.patch).to eq 0
			end
			Mmi::Semver.parse('1.2.3').tap do |v|
				expect(v.major).to eq 1
				expect(v.minor).to eq 2
				expect(v.patch).to eq 3
			end
		end
	end
end
