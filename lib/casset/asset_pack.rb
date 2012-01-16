module Casset
	class AssetPack
		DEFAULT_OPTIONS = {
			:show_filenames_inside => nil,
			:show_filenames_before => nil,
			:root => nil,
			:url_root => nil,
			:cache_dir => nil,
			:attr => {
				:js => nil,
				:css => nil,
			}
		}

		@options
		@type
		@assets

		def initialize(type, assets, config)
			@type, @assets = type, [*assets]
			@options = DEFAULT_OPTIONS.config_merge(config, :no_new => true, :overwrite => true)
		end

		def combine
			content = @assets.inject('') do |s, asset|
				s << "/* #{asset.url} */\n" if @options[:show_filenames_inside]
				s << asset.render << "\n"
			end
			return content
		end

		def write_file
			cache_dir = @options[:root] + @options[:cache_dir]
			Dir.mkdir(cache_dir) unless Dir.exist?(cache_dir)
			cache_file_name = cache_file_name()
			filename = cache_dir + cache_file_name
			file_url = @options[:url_root] + @options[:cache_dir] + cache_file_name
			# If filename exists, we don't need to generate the cache
			return file_url if File.exist?(filename)
			File.open(filename, 'w') { |f| f.write(combine()) }
			return file_url
		end

		def cache_file_name
			# Get the last modified time of all component files
			last_mtime = @assets.map{ |asset| asset.mtime }.max
			filename = Digest::MD5.hexdigest(@assets.inject('') \
					{ |s, asset| s << asset.path + (asset.minify? ? 'min' : '') } +
					last_mtime.to_s) + '.' + @type.to_s
			return filename
		end

		def tag(filename)
			r = ''
			if @options[:show_filenames_before]
				r << "<!-- File contains:\n" << @assets.map{ |a| " - #{a.url}" }.join("\n") << "\n-->"
			end
			attr = @options[:attr][@type] || {}
			case @type
			when :js
				attr.merge!(:type => "text/javascript", :src => filename)
				r << "<script " << attr.map{ |k,v| "#{k}=\"#{v}\"" }.join(" ") << "></script>"
			when :css
				attr.merge!(:rel => "stylesheet", :type => "text/css", :href => filename)
				r << "<link " << attr.map{ |k,v| "#{k}=\"#{v}\"" }.join(" ") << " />"
			else raise "Unknown asset type passed to tag: #{@type}"
			end
			return r
		end

		def inline_tag(content)
			r = ''
			if @options[:show_filenames_before]
				r << "<!-- File contains:\n" << @assets.map{ |a| " - #{a.url}" }.join("\n") << "\n-->"
			end
			attr = @options[:attr][@type] || {}
			case @type
			when :js
				attr.merge!(:type => "text/javascript")
				start = "<script " << attr.map{ |k,v| "#{k}=\"#{v}\"" }.join(" ") << ">\n"
				fin = "</script>\n"
			when :css
				attr.merge!(:type => "text/css")
				start = "<style " << attr.map{ |k,v| "#{k}=\"#{v}\"" }.join(" ") << ">\n"
				fin = "</style>\n"
			else raise "Unknown asset type passed to inline_tag: #{@type}"
			end
			r << start << content << fin
			return r
		end

		def render(options)
			options = {
				:inline => false,
				:gen_tags => false,
			}.merge(options)
			return options[:inline] ? render_inline(options[:gen_tags]) : render_files(options[:gen_tags])
		end

		def render_files(gen_tags)
			filename = (@assets.count == 1 && @assets[0].must_link_to?) ? @assets[0].url : write_file()
			return gen_tags ? tag(filename) : filename
		end

		def render_inline(gen_tags)
			content = combine()
			return gen_tags ? inline_tag(content) : content
		end
	end
end
