module Casset
	class Asset
		DEFAULT_OPTIONS = {
			:namespace => :core,
			:combine => nil,
			:min => nil,
			:min_file => nil,
		}

		attr_reader :type
		attr_reader :file
		attr_reader :path

		def initialize(type, file, options)
			@type, @file = type, file
			@remote = file.include?('://')
			# We don't yet know the path. We will after finalize() is called
			@path = nil
			@options = DEFAULT_OPTIONS.merge(options)
			# If the file's remote, we already have a few settings
			if @remote
				# Never combine remote assets
				@options[:combine] = false
				# We can, however, min them... But only by using :min_file
			end
		end

		def self.forge(type, file, options)
			case type
			when :js then JsAsset.new(file, options)
			when :css then CssAsset.new(file, options)
			else raise "Unknown asset type #{type}"
			end
		end

		# Called when we've finished mucking about with the Casset config
		def finalize(path_prefix, dirs, namespaces, combine, min)
			if @remote then @path = @file
			else						@path = path_prefix + dirs[@type] + namespaces[@options[:namespace]] + @file
			end
			@options[:combine] = combine if @options[:combine].nil?
			@options[:min] = min if @options[:min].nil?
		end

		def render
			"The conents of #{@file}"
		end

		def combine?
			@options[:combine]
		end

		def minify?
			@options[:min]
		end

		def mtime
			raise "Asset #{@path} doesn't appear to exist" unless File.exists?(@path)
			raise "Can't get the mtime of remote file #{@path}" if @remote
			File.mtime(@path)
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