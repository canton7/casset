module Casset
	class Asset
		DEFAULT_OPTIONS = {
			:namespace => 'core',
		}

		attr_reader :type
		attr_reader :file		
	
		def initialize(type, file, options)
			@type, @file = type, file
			@options = DEFAULT_OPTIONS.merge(options)
		end

		def self.forge(type, file, options)
			case type
			when :js then JsAsset.new(file, options)
			when :css then CssAsset.new(file, options)
			else raise "Unknown asset type #{type}"
			end
		end

		def render
			"The conents of #{@file}"
		end

	end


	class CssAsset < Asset
		def initialize(file, options)
			super(:css, file, options)
		end
	end

	class JsAsset < Asset
		def initialize(file, options)
			super(:js, file, options)
		end
	end
end
