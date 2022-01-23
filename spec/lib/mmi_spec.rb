RSpec.describe Mmi do
	describe '.fail!' do
		it 'prints a message to $stderr and exits' do
			expect(Kernel).to receive(:exit).with(1).once
			
			expect do
				Mmi.fail!('my super cool test message')
			end.to output("my super cool test message\n").to_stderr
		end
	end
end
