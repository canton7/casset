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
		attr_reader :url				# Only used for non-min, non-combined assets
		@path
		@options
		@remote
		@finalized

		def initialize(type, file, options)
			@type, @file = type, file
			# We don't yet know the path. We will after finalize() is called
			@path = nil
			@options = DEFAULT_OPTIONS.merge(options)
			@finalized = false
		end

		def self.forge(type, file, options)
			case type
			when :js then JsAsset.new(file, options)
			when :css then CssAsset.new(file, options)
			else raise "Unknown asset type #{type}"
			end
		end

		# Called when we've finished mucking about with the Casset config
		def finalize(root, dirs, namespaces, combine, min)
			namespace = namespaces[@options[:namespace]]
			@remote = @file.include?('://') || namespace.include?('://')
			if @remote
				@url = @path = @file
				# If it's remote, we can't combine it
				@options[:combine] = false
			else
				@url = namespace + dirs[@type] + @file
				@path = root + @url
				@options[:combine] = combine if @options[:ombine].nil?
			end
			@options[:min] = min if @options[:min].nil?
			@finalized = true
			raise Errno::ENOENT, "Asset #{@path} (#{File.absolute_path(@path)}) doesn't appear to exist" unless File.exists?(@path)
		end

		def render
			File.open(@path){ |f| f.read }
		end

		def combine?
			@options[:combine]
		end

		def minify?
			@options[:min]
		end

		def mtime
			raise "Must finalize asset before finding mtime" unless @finalized
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