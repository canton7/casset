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
			path_prefix, dirs, namespaces = config[:path_prefix], config[:dirs], config[:namespaces]
			combine = @options[:combine].nil? ? config[:combine] : @options[:combine]
			min = @options[:min].nil? ? config[:min] : @options[:min]
			each_asset do |asset|
				asset.finalize(path_prefix, dirs, namespaces, combine, min)
			end
		end

		# Partition the assets of a given type into those that are to be combined,
		# and those that aren't.
		# If an asset has no preference, the settings for this asset group are used.
		# If this is nil (no preference), the 'default' argument is used.
		def partition_combine(type)
			@assets[type].partition{ |asset| asset.combine? }
		end

		# Combines the files into the necessary cache files, doing writing, etc
		# along the way
		def combine(type)
			files = []
			render_comb, render_indv = partition_combine(type)
			p cache_file_name(render_comb, type)
			#render_comb.each do |asset|
				# Combined assets always live in a cache file.
			#end
		end

		def cache_file_name(assets, type)
			# Get the last modified time of all component files
			last_mtime = assets.map{ |asset| asset.mtime }.max
			filename = Digest::MD5.hexdigest(assets.inject('') \
					{ |s, asset| s << asset.path << asset.minify? ? 'min' : '' } +
					last_mtime.to_s)+type.to_s
			return filename
		end

	end
end
