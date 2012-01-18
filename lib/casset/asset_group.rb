require 'digest/md5'

module Casset
	class AssetGroup
		DEFAULT_OPTIONS = {
			:enable => nil,
			:depends_on => [],
			:inline => nil,
			:combine => nil,
			:min => nil,
			:minifiers => nil,
			:parsers => nil,
			:retain_filename => nil,
			:show_filenames_inside => nil,
			:show_filenames_before => nil,
			:attr => {
				:js => nil,
				:css => nil,
			},
			# Needed for assetpacks
			:root => nil,
			:url_root => nil,
			:cache_dir => nil,
		}

		attr_reader :name
		@options
		@assets
		@rendered

		def initialize(name, options={})
			@name = name
			@assets = {
				:js => [],
				:css => [],
			}
			# Ensure that this is an array
			options[:depends_on] = [*options[:depends_on]]
			@options = DEFAULT_OPTIONS.config_merge(options, :no_new => true)
			@options[:depends_on].uniq!
			@options[:enable] = false if @options[:enable].nil?
			@rendered = false
		end

		def set_options(options)
			@options.config_merge!(options, :overwrite => true, :no_new => true)
			@options[:depends_on].uniq!
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

		def enable
			@options[:enable] = true
		end

		def disable
			@options[:enable] = false
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
			@options.config_merge!(config, :no_new => true)
			@options.resolve_procs!
			each_asset do |asset|
				asset.finalize(@options.config_merge(config))
			end
		end

		# Combines the files into the necessary cache files, doing writing, etc
		# along the way
		def generate(type, options={})
			options = {
				:inline => false,
			}.merge(options)
			packs = []
			render_comb, render_indv = @assets[type].reject{ |a| options[:inline] ^ a.inline? }.partition{ |a| a.combine? }

			unless render_comb.empty?
				packs << AssetPack.new(type, render_comb, @options)
			end

			render_indv.each do |asset|
				packs << AssetPack.new(type, asset, @options)
			end
			return packs
		end
	end
end
