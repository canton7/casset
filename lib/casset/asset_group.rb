module Casset
	class AssetGroup
		DEFAULT_OPTIONS = {
			:enable => true,
			:depends_on = [],
		}

		attr_reader :name

		def initialize(name, ptions)
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
			
	end
end
