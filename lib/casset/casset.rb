# Temporary hack
$:.unshift File.dirname(__FILE__)

require 'asset'
require 'asset_group'

require 'ostruct'

module Casset
	class Casset

		def initialize()
			@groups = {}

			# Default config
			@config = {
				:dirs => {
					:js => 'js/',
					:css => 'css/',
				},
				:max_dep_depth => 5,
				:combine => true,
				:min => true,
				:namespaces => {
					:core => '',
				},
				:default_namespace => :core,
				:path_prefix => '',
			}
		end

		def config(&b)
			@config.merge!(ConfigStruct.block_to_hash(b))
		end

		def add_assets(type, group, files=nil, options=nil)
			# If they appeared to specify a group but no files, what they actually did
			# was a file but no group
			unless group.is_a?(Symbol)
				options, files, group = files || {}, group || [], nil
			end

			group ||= :page
			unless @groups.include?(group)
				@groups[group] = AssetGroup.new(group)
			end

			# Ensure we've got an array
			[*files].each do |file|
				# Get the namespace from the filename.
				# Don't attempt to resolve it, though. We're too lazy
				# Reverse ensures that, if no namespace present, nil is set
				file, namespace = file.split('::', 2).reverse
				options[:namespace] = namespace || @config[:default_namespace]
				asset = Asset.forge(type, file, options)
				@groups[group] << asset
			end
		end

		def js(*args)
			add_assets(:js, *args)
		end

		def css(*args)
			add_assets(:css, *args)
		end

		# Figures out which groups should be rendered, based on the current config
		def render
			# We're good to go. Assume no more config changes, and finalize
			@groups.values.each{ |group| group.finalize(@config) }

			# Filter down the list of groups into those that are actually going to be rendered
			groups = @groups.values.select do |group|
				group.enabled? && !group.empty?
			end

			# Sort out the deps
			groups = resolve_deps(groups)

			groups.each do |group|
				group.combine(:js)
			end
		end

		# Resolves dependancies, recursively
		# Creates a list of groups to be rendered, in order
		def resolve_deps(groups, depth=0)
			# Ensure we're working with an array
			groups = [*groups]
			raise "Recursion depth too great" if depth > @config[:max_dep_depth]
			all_groups = groups.inject([]) do |all_groups, group|
				dep_names = resolve_deps(group.depends_on, depth+1)
				# Turn this list of group names into a list of groups
				deps = dep_names.map{ |name| @groups[name] }
				# Don't add a group twice
				# This *should* work, as we're testing against the same instances...
				deps.select!{ |group| !all_groups.include(group) }
				all_groups.push *deps
				all_groups << group
			end
			return all_groups
		end
	end

	# From http://tagaholic.me/2009/01/21/block-to-hash-conversion-ruby.html
	class ConfigStruct < OpenStruct
		def self.block_to_hash(block=nil)
			config = self.new
			if block
				block.call(config)
				config.to_hash
			else
				{}
			end
		end

		def to_hash
			@table
		end
end

end
