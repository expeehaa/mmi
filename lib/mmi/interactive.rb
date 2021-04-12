require_relative 'interactive/updater'

module Mmi
	module Interactive
		class << self;
			def update(file_path, processor)
				Updater.new(file_path, processor).run!
			end
		end
	end
end
