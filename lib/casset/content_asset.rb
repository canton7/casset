module Casset
	class ContentAsset
		ASSET_TYPES = [:js, :css]

		DEFAULT_OPTIONS = {
			:combine => nil,
			:min => nil,
			:parser => nil,
			:minifier => nil,
			:request_path => nil,
			:inline => nil,
		}

		attr_reader :type
		@options
		@content
		@finalized
		@extension
		@cache_dir

		def initialize(type, content, options)
			raise "Unknown asset type #{type}" unless ASSET_TYPES.include?(type)
			@type, @content = type, content
			@options = DEFAULT_OPTIONS.config_merge(options, :no_new => true)
			# Strip period from extension
			@extension = options[:type] || type.to_s
			@finalized = false
		end

		# Called when we've finished mucking about with the Casset config
		def finalize(options)
			@options.config_merge!(options, :no_new => true)
			@options.resolve_procs!
			if options[:parsers][@type].include?(@extension)
				@options[:parser] = options[:parsers][@type][@extension][0]
			end
			@options[:minifier] = options[:minifiers][@type]
			@cache_dir = "#{options[:url_root]}#{options[:cache_dir]}"
			@finalized = true
		end

		def render
			content = @content
			# If there's a suitable parser, use that
			content = @options[:parser].parse(content) if @options[:parser]
			# Rewrite URLs in CSS files
			# We want the file's location as it was previously seen by the browser
			content = UriRewriter.rewrite_css(content, @options[:request_path], @cache_dir) if @type == :css
			# *Then* minify
			content = @options[:minifier].minify(content) if @options[:min] && @options[:minifier]
			return content.chomp
		end

		def path
			# Use this to show whether we've been modified... Return MD5 of contents
			Digest::MD5.hexdigest(@content)
		end

		def combine?
			@options[:combine]
		end

		def minify?
			@options[:min] && @options[:minifier]
		end

		def parse?
			@options[:parser]
		end

		def remote?
			false
		end

		def inline?
			@options[:inline]
		end

		def must_link_to?
			false
		end

		def mtime
			# Pretend we've never been modified. Show modification through "path", instead
			Time.at(0)
		end
	end
end