module Casset
	class Asset
		ASSET_TYPES = [:js, :css]

		DEFAULT_OPTIONS = {
			:combine => nil,
			:min => nil,
			:inline => nil,
			:parser => nil,
			:minifier => nil,
			:retain_filename => nil,
		}

		attr_reader :type
		attr_reader :file
		attr_reader :path
		attr_reader :url				# Only used for non-min, non-combined assets
		@options
		@remote
		@finalized
		@extension
		# Used for rewriting URLs in CSS files
		@cache_dir

		def initialize(type, file, options, min_file=nil)
			raise "Unknown asset type #{type}" unless ASSET_TYPES.include?(type)
			@type, @file, @min_file = type, file, min_file
			# We don't yet know the path. We will after finalize() is called
			@path = nil
			@options = DEFAULT_OPTIONS.config_merge(options, :no_new => true)
			# Strip period from extension
			@extension = File.extname(@file[:file])[1..-1]
			@finalized = false
		end

		# Called when we've finished mucking about with the Casset config
		def finalize(options)
			@options.config_merge!(options, :no_new => true)
			@options.resolve_procs!
			file_to_use = @min_file && @options[:min] ? @min_file : @file
			file = file_to_use[:file]
			namespace = options[:namespaces][file_to_use[:namespace]]
			# Allow namespace dir to override dir from options, and a leading / in the
			# asset path to override that
			if file.start_with?('/')
				dir = ''
				file.slice!(0) # Get rid of that leading slash
			elsif namespace.include?(:dirs) && namespace[:dirs].include?(@type)
				dir = namespace[:dirs][@type]
			else
				dir = options[:dirs][@type]
			end
			@remote = file.include?('://') || namespace[:path].include?('://')
			if @remote
				# We can't have inline remote assets, so don't even try.
				# This is superior to raising an exception, as user can set global inline
				@options[:inline] = false
				# Add on the namespace if the file doesn't have :// in it
				@url = @path = (file.include?('://') ? '' : namespace[:path]) + file
				# If it's remote, we can't combine it
				@options[:combine] = false
			else
				# URL is relative to the document root
				@url = "#{options[:url_root]}#{namespace[:path]}#{dir}#{file}"
				@path = "#{options[:root]}#{namespace[:path]}#{dir}#{file}"
				@cache_dir = "#{options[:url_root]}#{options[:cache_dir]}"
			end
			if options[:parsers][@type].include?(@extension)
				@options[:parser] = options[:parsers][@type][@extension][0]
			end
			@options[:minifier] = options[:minifiers][@type]
			@finalized = true
		end

		def render
			raise Errno::ENOENT, "Asset #{@path} (#{File.absolute_path(@path)}) doesn't exist" unless File.exists?(@path)
			raise "Can't render a remote file" if @remote
			content = File.open(@path) do |f|
				# If someone's got it locked for writing, wait until they've finished
				f.flock(File::LOCK_SH)
				f.read
			end
			# If there's a suitable parser, use that
			content = @options[:parser].parse(content) if @options[:parser]
			# Rewrite URLs in CSS files
			# We want the file's location as it was previously seen by the browser
			content = UriRewriter.rewrite_css(content, File.dirname(@url), @cache_dir) if @type == :css
			# *Then* minify
			content = @options[:minifier].minify(content) if @options[:min] && @options[:minifier] && !@options[:min_file]
			return content.chomp
		end

		def combine?
			# Safety check on @remote, although if @remote = true, combine should be false
			@options[:combine] && !@remote
		end

		def minify?
			@options[:min] && @options[:minifier]
		end

		def parse?
			@options[:parser]
		end

		def remote?
			@remote
		end

		def inline?
			@options[:inline]
		end

		def must_link_to?
			# Can link directory so long as we don't minify, combine, or parse
			# We must always link to remote files
			@remote || (!@options[:combine] && !@options[:min] && !@options[:parser] && @options[:retain_filename])
		end

		def mtime
			raise "Must finalize asset before finding mtime" unless @finalized
			raise "Can't get the mtime of remote file #{@path}" if @remote
			File.mtime(@path)
		end
	end
end
