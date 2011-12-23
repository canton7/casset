module Casset
	class AssetPack
		DEFAULT_OPTIONS = {
			:show_filenames_inside => nil,
			:show_filenames_before => nil,
			:root => nil,
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
			cache_dir = @options[:root] + @options[:cache_dir]
			Dir.mkdir(cache_dir) unless Dir.exist?(cache_dir)
			filename = cache_file_name(cache_dir)
			# If filename exists, we don't need to generate the cache
			return if File.exist?(filename)
			unless File.exist?(filename)
				content = @assets.inject('') do |s, asset|
					s << "/* #{asset.url} */\n" if @options[:show_filenames_inside]
					s << asset.render + "\n"
				end
				File.open(filename, 'w') { |f| f.write(content) }
			end
			return filename
		end

		def cache_file_name(cache_dir)
			# Get the last modified time of all component files
			last_mtime = @assets.map{ |asset| asset.mtime }.max
			filename = Digest::MD5.hexdigest(@assets.inject('') \
					{ |s, asset| s << asset.path + (asset.minify? ? 'min' : '') } +
					last_mtime.to_s) + '.' + @type.to_s
			return cache_dir + filename
		end

		def tag(filename)
			r = ''
			if @options[:show_filenames_before]
				r << "<!-- File contains:\n" + @assets.map{ |a| " - #{a.url}" }.join("\n") + "\n-->"
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

		def render(gen_tags)
			filename = (@assets.count == 1 && @assets[0].must_link_to?) ? @assets[0].url : combine()
			return gen_tags ? tag(filename) : filename
		end
	end
end