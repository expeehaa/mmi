require 'open3'

RSpec.describe 'exe/mmi' do
	def run_script(*args, stdin: nil)
		arguments = [
			'ruby',
			File.expand_path('../../exe/mmi', __dir__),
		] + args
		
		Open3.capture3(*arguments, stdin_data: stdin)
	end
	
	describe 'without arguments' do
		it 'returns with an error' do
			stdout, stderr, status = run_script
			
			aggregate_failures do
				expect(stdout           ).to eq "No file given.\n"
				expect(stderr           ).to eq ''
				expect(status.exitstatus).to eq 1
			end
		end
	end
	
	EXAMPLE_CONFIGS = Dir[File.expand_path('../../examples/*', __dir__)]
	
	describe EXAMPLE_CONFIGS do
		it 'contains some elements' do
			expect(EXAMPLE_CONFIGS.size).to eq 1
		end
	end
	
	EXAMPLE_CONFIGS.each do |config_file|
		context "with file #{config_file}" do
			describe 'subcommand validate' do
				it 'runs without an error' do
					stdout, stderr, status = run_script(config_file, 'validate')
					
					aggregate_failures do
						expect(stdout           ).to eq "File is valid.\n"
						expect(stderr           ).to eq ''
						expect(status.exitstatus).to eq 0
					end
				end
			end
		end
	end
end
