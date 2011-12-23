# Temporary hack
$:.unshift File.dirname(__FILE__)

require 'casset/monkey'
require 'casset/asset'
require 'casset/asset_group'
require 'casset/asset_pack'
require 'casset/parser'
require 'casset/minifier'

require 'ostruct'

module Casset
	class Casset
		@groups
		@options

		def initialize()
			@groups = {}

			# Default config
			@config = {
				:dirs => {
					:js => 'js/',
					:css => 'css/',
				},
				:cache_dir => 'cache/',
				:max_dep_depth => 5,
				:combine => true,
				:min => true,
				:minifiers => {
					:js => nil,
					:css => nil,
				},
				:parsers => {
					:js => {},
					:css => {},
				},
				:namespaces => {
					:core => '',
				},
				:default_namespace => :core,
				:root => '',
				# If asset is not combined, will retain old filename
				:retain_filename => true,
				:show_filenames_before => false,
				:show_filenames_inside => false,
				:attr => {
					:js => nil,
					:css => nil
				}
			}
		end

		def config(config=nil, &b)
			config = ConfigStruct.block_to_hash(b) unless config
			@config.config_merge!(config, :overwrite => true)
		end

		def add_assets(type, *args)
			# We can take inputs in several formats...
			# - :type, [files]
			# - :type, :group, [files]
			# - :type, [files], {options}
			# - :type, :group, [files], {options}
			case args.count
			when 1 then group, files, options = nil, args[0], {}
			when 2
				unless args[1].is_a?(Hash)
					group, files, options = args[0], args[1], {}
				else
					group, files, options = nil, args[0], args[1]
				end
			when 3 then group, files, options = args[0], args[1], args[2]
			else raise "Too many arguments given to js/css"
			end

			# Can't call to_sym on nil
			group = (group || :page).to_sym
			@groups[group] = AssetGroup.new(group, :enable => true) unless @groups.include?(group)

			add_assets_to_group(type, group, files, options)
		end

		def add_group(name, options={})
			name = name.to_sym
			js = options.delete(:js) || []
			css = options.delete(:css) || []
			@groups[name] = AssetGroup.new(name, options) unless @groups.include?(name)
			add_assets_to_group(:js, name, js)
			add_assets_to_group(:css, name, css)
		end

		def add_assets_to_group(type, group, files, options={})
			# Ensure we've got an array
			[*files].each do |file|
				# Get the namespace from the filename.
				# Don't attempt to resolve it, though. We're too lazy
				# Reverse ensures that, if no namespace present, nil is set
				file, namespace = file.split('::', 2).reverse
				options[:namespace] = namespace || @config[:default_namespace]
				asset = Asset.new(type, file, options)
				@groups[group] << asset
			end
		end

		def group_options(group, options)
			raise "Can't set options for group #{group} as it doesn't exist" unless @groups.include?(group)
			@groups[group].set_options(options)
		end

		def js(*args)
			add_assets(:js, *args)
		end

		def css(*args)
			add_assets(:css, *args)
		end

		# Figures out which groups should be rendered, based on the current config
		def render(type, options={})
			options = {
					:gen_tags => true
			}.merge(options)
			# We're good to go. Assume no more config changes, and finalize
			@groups.values.each{ |group| group.finalize(@config) }

			# Filter down the list of groups into those that are actually going to be rendered
			groups = @groups.values.select do |group|
				group.enabled? && !group.empty?
			end

			# Sort out the deps
			groups = resolve_deps(groups)

			# Generate all cache files, if needed, and get an array of generated packs
			packs = groups.inject([]){ |s, group| s.push *group.generate(type) }
			files = packs.map{ |pack| pack.render(options[:gen_tags]) }
			# If returning tags, make them a string from an array
			files = files.join("\n") if options[:gen_tags]
			return files
		end

		# Resolves dependancies, recursively
		# Creates a list of groups to be rendered, in order
		def resolve_deps(groups, depth=0)
			raise "Recursion depth too great" if depth > @config[:max_dep_depth]
			all_groups = []
			[*groups].each do |group|
				unless group.depends_on.empty?
					dep_groups = group.depends_on.map{ |name| @groups[name] }
					deps = resolve_deps(dep_groups, depth+1)
					# Don't add a group twice
					deps.select!{ |group| !all_groups.include?(group) }
					all_groups.push *deps
				end
				all_groups << group unless all_groups.include?(group)
			end
			return all_groups
		end

		def add_parser(type, parser)
			raise "Unknown parser type #{type}" unless @config[:parsers].include?(type)
			parser.extensions.each do |ext|
				@config[:parsers][type][ext] = [] unless @config[:parsers].include?(ext)
				# Add onto beginning -- higher priority
				@config[:parsers][type][ext].unshift parser
			end
		end

		def set_minifier(type, minifier)
			raise "Unknown minifier type #{type}" unless @config[:minifiers].include?(type)
			@config[:minifiers][type] = minifier
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