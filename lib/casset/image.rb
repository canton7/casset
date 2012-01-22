module Casset
	class Image
		DEFAULT_OPTIONS = {
			:namespace => :core,
			:embed => false,
			:request_path => nil,
		}

		@path
		@attr
		@options
		@finalized

		def initialize(path, alt, attr={})
			@options = DEFAULT_OPTIONS.config_clone
			# For conveniene, we allow "magic" attrs, which are actually the options
			# Overwrite option with value from attr, if it exists, removing from attr
			@options.each{ |k,v| @options[k] = attr.delete(k) || v }
			@path, @attr = path, attr
			# We make them specify the alt explicitely for convenience
			@attr[:alt] = alt
			@finalized = false
		end

		def tag(options)
			finalize(options)
			"<img " << @attr.map{ |k,v| "#{k}=\"#{v}\"" }.join(" ") << " />"
		end

		def src(options)
			finalize(options)
			@attr[:src]
		end

		def finalize(options)
			return if @finalized
			# We know the namespaces at this point..
			namespace = options[:namespaces][@options[:namespace]]
			if @path.start_with?('/')
				@path.slice!(0)
				dir = ''
			elsif namespace.include?(:dirs) && namespace[:dirs].include?(:img)
				dir = namespace[:dirs][:img]
			else
				dir = options[:dirs][:img]
			end
			if @path.include?('://')
				url = @path
			elsif namespace[:path].include?('://')
				url = "#{namespace[:path]}#{@path}"
			else
				url = UriRewriter.rewrite_url(options[:request_path], "#{options[:url_root]}#{namespace[:path]}#{dir}#{@path}")
			end
			@attr[:src] = url
			@finalized = true
		end
	end
end
