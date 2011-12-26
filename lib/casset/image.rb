module Casset
	class Image
		DEFAULT_OPTIONS = {
			:namespace => :core,
			:embed => false,
		}

		@path
		@attr
		@options

		def initialize(path, alt, attr={})
			@options = DEFAULT_OPTIONS.config_clone
			# For conveniene, we allow "magic" attrs, which are actually the options
			# Overwrite option with value from attr, if it exists, removing from attr
			@options.each{ |k,v| @options[k] = attr.delete(k) || v }
			@path, @attr = path, attr
			# We make them specify the alt explicitely for convenience
			@attr[:alt] = alt
		end

		def tag(options)
			# We know the namespaces at this point..
			namespace = options[:namespaces][@options[:namespace]]
			if @path.include?('://')
				url = @path
			elsif namespace.include?('://')
				url = namespace + @path
			else
				url = options[:url_root] + namespace + options[:dirs][:img] + @path
			end
			@attr[:src] = url
			#TODO embedding
			"<img " << @attr.map{ |k,v| "#{k}=\"#{v}\"" }.join(" ") << " />"
		end
	end
end
