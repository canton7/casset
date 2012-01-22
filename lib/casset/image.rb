module Casset
	class Image
		DEFAULT_OPTIONS = {
			:namespace => :core,
			:embed => false,
			:request_path => nil,
			:show_image_size => nil,
		}

		@file
		@path
		@attr
		@options
		@finalized

		def initialize(file, alt, attr={})
			@options = DEFAULT_OPTIONS.config_clone
			# For conveniene, we allow "magic" attrs, which are actually the options
			# Overwrite option with value from attr, if it exists, removing from attr
			@options.each{ |k,v| @options[k] = attr.delete(k) || v }
			# Allow them to use :size OR :show_image_size, as the latter is rather verbose
			@options[:show_image_size] = attr.delete(:size) if attr.has_key?(:size)
			@file,  @attr = file, attr
			# We make them specify the alt explicitely for convenience
			@attr[:alt] = alt
			@finalized = false
		end

		def tag(options)
			finalize(options)
			dimensions = nil
			if @options[:show_image_size] && !defined?(Dimensions)
				raise "Install the 'dimensions' gem to use the :show_image_size/:size feature for images"
			end
			if @options[:show_image_size] && File.exists?(@path)
				dimensions = Dimensions.dimensions(@path)
			end
			@attr.merge!(:width => dimensions[0], :height => dimensions[1]) if dimensions
			"<img " << @attr.map{ |k,v| "#{k}=\"#{v}\"" }.join(" ") << " />"
		end

		def src(options)
			finalize(options)
			@attr[:src]
		end

		def finalize(options)
			return if @finalized
			@options.config_merge!(options, :no_new => true)
			# We know the namespaces at this point..
			namespace = options[:namespaces][@options[:namespace]]
			if @file.start_with?('/')
				@file.slice!(0)
				dir = ''
			elsif namespace.include?(:dirs) && namespace[:dirs].include?(:img)
				dir = namespace[:dirs][:img]
			else
				dir = options[:dirs][:img]
			end
			if @file.include?('://')
				src = @path = @file
			elsif namespace[:path].include?('://')
				src = @path = "#{namespace[:path]}#{@file}"
			else
				@path = "#{options[:root]}#{namespace[:path]}#{dir}#{@file}"
				src = UriRewriter.rewrite_url(options[:request_path], "#{options[:url_root]}#{namespace[:path]}#{dir}#{@file}")
			end
			@attr[:src] = src
			@finalized = true
		end
	end
end
