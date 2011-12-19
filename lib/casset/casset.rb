require 'asset'

module Casset
	class Casset
		
		def initialize()
			@groups = {}

			# Default config
			@config = {
				:js_dir => '',
				:css_dir => '',
				:max_dep_depth => 5,
			}
		end

		def add_assets(type, group, files, options)
			group ||= :page
			group = group.to_sym
			unless @groupsinclude?(group)
				@groups[group] = AssetGroup.new(group)
			end
			# Ensure we've got an array
			[*files].each do |file|
				# Get the namespace from the filename.
				# Don't attempt to resolve it, though. We're too lazy
				# Reverse ensure that, if no namespace present, nil is set
				file, namespace = file.split('::', 2).reverse
				options[:namespace] = namespace || @config[:default_namespace]
				asset = Asset.forge(type, file, options)
				@groups[group] << asset
			end
		end

		def js(group=nil, file, options)
			add_asset(:js, group, file, options)	
		end

		def css(group=nil, file, options)
			add_asset(:css, group, file, options)
		end

		# Figures out which groups should be rendered, based on the current config
		def groups_to_render
			# Filter down the list of groups into those that are actually going to be rendered
			groups = @groups.values.select do |group|
				group.enabled? && !group.empty?
			end
			
			# Sort out the deps
			groups = resolve_deps(groups)
		end

		# Resolves dependancies, recursively
		# Creates a list of groups to be rendered, in order
		def resolve_deps(groups, depth=0)
			# Ensure we're working with an array
			groups = [*groups]
			raise "Recursion depth too great" if depth > @options[:max_dep_depth]
			all_groups = groups.inject([]) do |all_groups, group|
				dep_names = resolve_deps(group.depends_on, depth+1)
				# Turn this list of group names into a list of groups
				deps = dep_names.map{ |name| @groups[name] }
				# Don't add a group twice
				# This *should* work, as we're testing against the same instances...
				deps.select!{ |group| !all_groups.include(group) }
				all_groups << *deps
				all_groups << group
			end
			return all_groups
		end
	end
end
