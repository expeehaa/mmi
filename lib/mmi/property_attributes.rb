module Mmi
	module PropertyAttributes
		def initialize(hash)
			@hash = hash
		end
		
		def to_h
			@hash
		end
		
		def [](key)
			@hash[key]
		end
		
		module ClassMethods
			PropertyConfiguration = Struct.new(:key, :type, :required, :default, :requires, :conflicts, :validate)
			
			def registered_properties
				@registered_properties ||= {}
			end
			
			def property(method_name, key=method_name.to_s, type: nil, required: nil, default: nil, requires: [], conflicts: [], validate: nil)
				raise(ArgumentError, '"method_name" must be a Symbol'         ) if !method_name.is_a?(Symbol)
				raise(ArgumentError, %Q{#{type.inspect} is not a valid "type"}) if !valid_atomic_type?(type) && !valid_hash_type?(type)
				
				requires  = [requires ] if !requires .is_a?(Array)
				conflicts = [conflicts] if !conflicts.is_a?(Array)
				
				raise(ArgumentError, '"required" is mutually exclusive with "requires" and "conflicts"') if required && (requires.any? || conflicts.any?)
				raise(ArgumentError, '"requires" and "conflicts" must not share entries'               ) if requires.intersect?(conflicts)
				raise(ArgumentError, '"required" is mutually exclusive with "default"'                 ) if required && !default.nil?
				
				required = requires.none? && conflicts.none? && default.nil? if required.nil?
				
				raise(ArgumentError, '"validate" must be nil, a symbol or a Proc') if !validate.nil? && !validate.is_a?(Symbol) && !validate.is_a?(Proc)
				
				registered_properties[method_name] = PropertyConfiguration.new(key: key, type: type, required: required, default: default, requires: requires, conflicts: conflicts, validate: validate)
				
				define_method(method_name) do
					parsed_property_store[method_name]
				end
			end
			
			def parse(hash)
				new(hash).parse!
			end
			
			def valid_atomic_type?(type)
				type.nil? || type.respond_to?(:parse)
			end
			
			def valid_hash_type?(type_hash)
				type_hash.is_a?(Hash) && type_hash.key?(:field) && type_hash.key?(:types) && type_hash.fetch(:types).is_a?(Hash) && type_hash.fetch(:types).all? do |_, type|
					valid_atomic_type?(type)
				end
			end
		end
		
		def self.prepended(klass)
			klass.extend(ClassMethods)
		end
		
		def parsed_property_store
			@parsed_property_store ||= {}
		end
		
		class ValidationError < StandardError; end
		
		def validate_constraints!
			errors =
				self.class.registered_properties.map do |method_name, configuration|
					[
						method_name,
						[].tap do |property_errors|
							if configuration.required && !@hash.key?(configuration.key)
								property_errors << "missing field #{configuration.key}"
							elsif !configuration.required && @hash.key?(configuration.key)
								if (missing_requires = configuration.requires.reject{ |e| @hash.key?(e) }).any?
									property_errors << "missing required field(s) #{missing_requires.map(&:inspect).join(', ')}"
								end
								
								if (present_conflicts = configuration.conflicts.select{ |e| @hash.key?(e) }).any?
									property_errors << "conflicting with field(s) #{present_conflicts.map(&:inspect).join(', ')}"
								end
							end
							
							if @hash.key?(configuration.key) && self.class.valid_hash_type?(configuration.type)
								if !@hash.fetch(configuration.key).is_a?(Hash)
									property_errors << "field #{configuration.key.inspect} must be a Hash"
								elsif !@hash.fetch(configuration.key).key?(configuration.type[:field]) || !configuration.type[:types].keys.include?(@hash.fetch(configuration.key).fetch(configuration.type[:field]))
									property_errors << "field #{configuration.key.inspect} must have key #{configuration.type[:field].inspect} with one of values #{configuration.type[:types].keys.map(&:inspect).join(', ')}"
								end
							end
							
							if @hash.key?(configuration.key) && configuration.validate
								deduced_proc =
									if configuration.validate.is_a?(Symbol)
										self.class.method(configuration.validate)
									else
										configuration.validate
									end
								
								deduced_proc.call(@hash[configuration.key], property_errors)
							end
						end,
					]
				end.select do |_, property_errors|
					property_errors.any?
				end.to_h
			
			if errors.none?
				true
			else
				raise(ValidationError, errors.map do |method_name, property_errors|
					"#{method_name}: #{property_errors.join(', ')}"
				end.join('; '))
			end
		end
		
		def parse!
			validate_constraints!
			
			self.class.registered_properties.each do |method_name, configuration|
				if !@hash.key?(configuration.key)
					if configuration.required || !configuration.default.nil?
						parsed_property_store[method_name] = configuration.default
					else
						# Do nothing.
					end
				elsif configuration.type.nil?
					parsed_property_store[method_name] = self[configuration.key]
				else
					deduced_type =
						if self.class.valid_hash_type?(configuration.type)
							configuration.type[:types].fetch(self[configuration.key][configuration.type[:field]])
						else
							configuration.type
						end
					
					initializer_proc = proc do |item|
						deduced_type.parse(item)
					end
					
					parsed_property_store[method_name] =
						self[configuration.key].then do |value|
							value.is_a?(Array) ? value.map(&initializer_proc) : initializer_proc[value]
						end
				end
			end
			
			self
		end
		
		def update_properties!(properties)
			raise(ArgumentError, 'argument must be a Hash'                                ) if !properties.is_a?(Hash)
			raise(ArgumentError, 'argument can only have keys that are defined properties') if (properties.keys - self.class.registered_properties.keys).any?
			
			old_property_store     = @parsed_property_store
			@parsed_property_store = nil
			
			old_properties = properties.map do |method_name, value|
				key = self.class.registered_properties[method_name].key
				
				old_value = @hash[key]
				
				if !value.nil?
					@hash[key] = value
				elsif @hash.key?(key)
					@hash.delete(key)
				end
				
				[method_name, old_value]
			end
			
			parse!
		rescue ValidationError
			@parsed_property_store = old_property_store
			
			old_properties.each do |method_name, old_value|
				key = self.class.registered_properties[method_name].key
				
				if !old_value.nil?
					@hash[key] = old_value
				elsif @hash.key?(key)
					@hash.delete(key)
				end
			end
			
			raise
		end
	end
end
