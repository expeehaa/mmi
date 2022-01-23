module Mmi
	module OptionAttributes
		attr_reader :options
		
		def self.included(klass)
			klass.extend(ClassMethods)
		end
		
		module ClassMethods
			def opt_reader(attr, name=attr.to_s, &block)
				define_method(:"#{attr.to_sym}") do
					result = self.options[name]
					
					if result.nil? && block_given?
						yield
					else
						result
					end
				end
			end
			
			def opt_writer(attr, name=attr.to_s)
				define_method(:"#{attr.to_sym}=") do |value|
					if value.nil?
						self.options.delete(name)
					else
						self.options[name] = value
					end
				end
			end
			
			def opt_accessor(attr, name=attr.to_s, &block)
				opt_reader(attr, name, &block)
				opt_writer(attr, name        )
			end
		end
	end
end