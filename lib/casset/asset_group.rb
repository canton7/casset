require 'digest/md5'

module Casset
	class AssetGroup
		DEFAULT_OPTIONS = {
			:enable => true,
			:depends_on => [],
			:inline => nil,
			:combine => nil,
			:min => nil,
		}

		attr_reader :name
		@cache_dir

		def initialize(name, options={})
			@name = name
			@assets = {
				:js => [],
				:css => [],
			}
			@options = DEFAULT_OPTIONS.merge(options)
			@rendered = false
		end

		def js
			@assets[:js]
		end

		def css
			@assets[:css]
		end

		def add(asset)
			raise "Unknown asset type #{asset.type}" unless @assets.include?(asset.type)
			@assets[asset.type] << asset
		end

		# TODO replace this with a proper alias
		def <<(asset)
			add(asset)
		end

		def render(types=nil)
			types = [*types] || @assets.keys
			types.each do |type|

			end
			@rendered = true
		end

		def enabled?
			@options[:enable]
		end

		def rendered?
			@rendered
		end

		def depends_on
			@options[:depends_on]
		end

		def empty?
			@assets.values.inject(true){ |res, list| res &&= list.empty? }
		end

		def each_type
			@assets.values.each do |type|
				yield type
			end
		end

		def each_asset
			@assets.values.each do |type|
				type.each do |asset|
					yield asset
				end
			end
		end

		# Called when we've finished mucking about with the Casset config
		def finalize(config)
			root, dirs, namespaces = config[:root], config[:dirs], config[:namespaces]
			combine = @options[:combine].nil? ? config[:combine] : @options[:combine]
			min = @options[:min].nil? ? config[:min] : @options[:min]
			@cache_dir = config[:root] + config[:cache_dir]
			each_asset do |asset|
				asset.finalize(root, dirs, namespaces, combine, min)
			end
			Dir.mkdir(@cache_dir) unless Dir.exist?(@cache_dir)
		end

		# Combines the files into the necessary cache files, doing writing, etc
		# along the way
		def generate(type)
			files = []
			render_comb, render_indv = @assets[type].partition{ |asset| asset.combine? }
			#p cache_file_name(render_comb, type)
			#render_comb.each do |asset|
				# Combined assets always live in a cache file.
			#end

			unless render_comb.empty?
				files << combine(type, render_comb)
			end



			render_indv.each do |asset|
				if asset.minify?
				else
					# Don't minimise or combine -- just link to file
					# TODO this won't swing with SASS, etc. We probably want to put it in
					# a cache file anyway
					files << asset.url
				end
			end
			return files
		end

		def combine(type, assets)
			filename = cache_file_name(type, assets)
			# If filename exists, we don't need to generate the cache
			return filename if File.exist?(filename)
			unless File.exist?(filename)
				content = assets.inject('') do |s, asset|
					s << asset.render + "\n"
				end
				File.open(filename, 'w') { |f| f.write(content) }
			end
			return filename
		end

		def cache_file_name(type, assets)
			# Get the last modified time of all component files
			last_mtime = assets.map{ |asset| asset.mtime }.max
			filename = Digest::MD5.hexdigest(assets.inject('') \
					{ |s, asset| s << asset.path + (asset.minify? ? 'min' : '') } +
					last_mtime.to_s) + '.' + type.to_s
			return @cache_dir + filename
		end

	end
end
