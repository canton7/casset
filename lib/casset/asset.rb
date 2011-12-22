module Casset
	class Asset
		ASSET_TYPES = [:js, :css]

		DEFAULT_OPTIONS = {
			:namespace => :core,
			:combine => nil,
			:min => nil,
			:min_file => nil,
			:parsers => nil,
			:minifiers => nil,
		}

		attr_reader :type
		attr_reader :file
		attr_reader :path
		attr_reader :url				# Only used for non-min, non-combined assets
		@path
		@options
		@remote
		@finalized
		@extension

		def initialize(type, file, options)
			raise "Unknown asset type #{type}" unless ASSET_TYPES.include?(type)
			@type, @file = type, file
			# We don't yet know the path. We will after finalize() is called
			@path = nil
			@options = DEFAULT_OPTIONS.merge(options)
			@finalized = false
		end

		# Called when we've finished mucking about with the Casset config
		def finalize(options)
			@options.config_merge!(options, :no_new => true)
			namespace = options[:namespaces][@options[:namespace]]
			@remote = @file.include?('://') || namespace.include?('://')
			if @remote
				@url = @path = @file
				# If it's remote, we can't combine it
				@options[:combine] = false
			else
				@url = namespace + options[:dirs][@type] + @file
				@path = options[:root] + @url
			end
			@finalized = true
			# Strip period from extension
			@extension = File.extname(@file)[1..-1]
			raise Errno::ENOENT, "Asset #{@path} (#{File.absolute_path(@path)}) doesn't appear to exist" unless File.exists?(@path)
		end

		def render
			raise "Can't render a remote file" if @remote
			content = File.open(@path){ |f| f.read }
			# If there's a suitable parser, use that
			if @options[:parsers] && @options[:parsers][@type].include?(@extension)
				content = @options[:parsers][@type][@extension][0].parse(content)
			end
			if @options[:min] && @options[:minifiers] && @options[:minifiers][@type]
				content = @options[:minifiers][@type].minify(content)
			end
			return content
		end

		def combine?
			@options[:combine]
		end

		def minify?
			@options[:min]
		end

		def can_link?
			# Can link directory so long as we don't minify, combine, or parse
			!@options[:combine] && !@options[:min] && !@options[:parsers][@type].include?(@extension)
		end

		def mtime
			raise "Must finalize asset before finding mtime" unless @finalized
			raise "Can't get the mtime of remote file #{@path}" if @remote
			File.mtime(@path)
		end

	end
end