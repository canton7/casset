# Temporary hack
$:.unshift File.dirname(__FILE__)

require 'casset/monkey'
require 'casset/asset'
require 'casset/content_asset'
require 'casset/asset_group'
require 'casset/asset_pack'
require 'casset/parser'
require 'casset/minifier'
require 'casset/image'
require 'casset/uri_rewriter'
require 'casset/version'

require 'ostruct'
begin
	require 'dimensions'
rescue LoadError
end

module Casset
	class Casset
		DEFAULT_OPTIONS = {
			:dirs => {
				:js => 'js/',
				:css => 'css/',
				:img => 'img/',
			},
			:cache_dir => 'cache/',
			:max_dep_depth => 5,
			:combine => true,
			:min => true,
			:inline => false,
			:minifiers => {
				:js => nil,
				:css => nil,
			},
			:parsers => {
			},
			:namespaces => {
				:core => {:path => ''},
			},
			:default_namespace => :core,
			# The file root -- where the namespaces are relative to
			:root => 'public/',
			# The URL root -- where the namespaces are relative to, as URLs
			:url_root => '',
			# The path of the page we're currently on. Can be set by render
			:request_path => '',
			# If asset is not combined, will retain old filename
			:retain_filename => true,
			:show_filenames_before => false,
			:show_filenames_inside => false,
			:attr => {
				:js => nil,
				:css => nil
			},
			# Show image width and height attributes
			:show_image_size => false,
		}

		@groups
		@options
		@finalized
		@groups_to_render

		def initialize()
			@groups = {}
			@options = DEFAULT_OPTIONS.config_clone
			@finalized = false
			@groups_to_render = []
		end

		def config(config=nil, &b)
			config = ConfigStruct.block_to_hash(b) unless config
			@options.config_merge!(config.config_clone, :overwrite => true)
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
			options = options.config_clone
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
				if options[:content]
					asset = ContentAsset.new(type, file, options)
				else
					# Get the namespace from the filename.
					# Don't attempt to resolve it, though. We're too lazy
					# Reverse ensures that, if no namespace present, nil is set
					file, namespace = file.split('::', 2).reverse
					file = {:file => file, :namespace => (namespace || @options[:default_namespace]).to_sym}
					if options[:min_file]
						min_file, min_namespace = options.delete(:min_file).split('::', 2).reverse
						min_file = {:file => min_file, :namespace => (min_namespace || @options[:default_namespace]).to_sym}
					else
						min_file = nil
					end
						asset = Asset.new(type, file, options, min_file)
				end

				@groups[group] << asset
				# If they specified options which aren't acceptable to the file, apply to the group
				group_options = options.select{ |key| !Asset::DEFAULT_OPTIONS.include?(key) }
				# If one of those was attr, adjust it (as is js- or css-specific)
				group_options[:attr] = {type => group_options[:attr] } if group_options.include?(:attr)
				@groups[group].set_options(group_options)
			end
		end

		def group_options(group, options)
			raise "Can't set options for group #{group} as it doesn't exist" unless @groups.include?(group)
			@groups[group].set_options(options)
		end

		def add_namespace(key, path)
			# path can either be the path to the namespace, or hash of :path, :dirs
			namespace = path.is_a?(Hash) ? path : {:path => path}
			@options[:namespaces][key.to_sym] = namespace
		end
		alias_method :set_namespace, :add_namespace

		def set_default_namespace(key=:core)
			raise "Can's set default namespace to #{key} as no such namespace exists" unless @options[:namespaces].include?(key)
			@options[:default_namespace] = key.to_sym
		end

		def js(*args)
			add_assets(:js, *args)
		end

		def css(*args)
			add_assets(:css, *args)
		end

		def add_content_assets(type, *args)
			if args[-1].is_a?(Hash)
				args[-1][:content] = true
			else
				args << {:content => true}
			end
			add_assets(type, *args)
		end

		def js_content(*args)
			add_content_assets(:js, *args)
		end

		def css_content(*args)
			add_content_assets(:css, *args)
		end

		def finalize
			# We're good to go. Assume no more config changes, and finalize
			# Resolve any procs in our config.
			@options.resolve_procs!
			# Sort out namespaces...
			@groups.values.each{ |group| group.finalize(@options) }

			# Filter down the list of groups into those that are actually going to be rendered
			groups = @groups.values.select do |group|
				group.enabled? && !group.empty?
			end

			# Sort out the deps
			@groups_to_render = resolve_deps(groups)
		end

		# Figures out which groups should be rendered, based on the current config
		def render(type=:all, options={})
			if type == :all
				# Rely on the face that << works on both strings and arrays
				# and that gen_tags is either set for both (so return array), or none
				# (so return string)
				js = render(:js, options)
				css = render(:css, options)
				# Since we're rendering all assets, if we're not separating js and css by
				# tags, separate them into a hash instead
				if options[:gen_tags] == false
					return {:js => js, :css => css}
				else
					return js << css
				end
			end

			options = {
					:gen_tags => true,
					:inline => false,
					:request_path => @options[:request_path],
			}.merge(options)

			finalize() unless @finalized
			@finalized = true

			# Generate all cache files, if needed, and get an array of generated packs
			packs = @groups_to_render.inject([]){ |s, group| s.push(*group.generate(type, :inline => options[:inline])) }
			files = packs.map{ |pack| pack.render(options) }
			# If returning tags, make them a string from an array
			# Similarly, join inline assets, if they're of the same type
			files = files.join("\n") if options[:gen_tags] || options[:inline]
			return files
		end

		def render_inline(type=:all, options={})
			return render(type, options.merge(:inline => true))
		end

		# Resolves dependancies, recursively
		# Creates a list of groups to be rendered, in order
		def resolve_deps(groups, depth=0)
			raise "Recursion depth too great" if depth > @options[:max_dep_depth]
			all_groups = []
			[*groups].each do |group|
				unless group.depends_on.empty?
					dep_groups = group.depends_on.map do |name|
						raise "Unknown group #{name} as a dependeny for #{group.name}" unless @groups.include?(name)
						@groups[name]
					end
					deps = resolve_deps(dep_groups, depth+1)
					# Don't add a group twice
					deps.select!{ |g| !all_groups.include?(g) }
					all_groups.push(*deps)
				end
				all_groups << group unless all_groups.include?(group)
			end
			return all_groups
		end

		def enable(group_name)
			raise "Unknown group #{group_name}" unless @groups.include?(group_name)
			@groups[group_name].enable
		end

		def disable(group_name)
			raise "Unkown group #{group_name}" unless @groups.include?(group_name)
			@groups[group_name].disable
		end

		def set_parser(*extensions, &blk)
			parser = Parser.new(*extensions, &blk)
			parser.extensions.each do |ext|
				@options[:parsers][ext] = parser
			end
		end

		def set_minifier(type, &blk)
			raise "Unknown minifier type #{type}" unless @options[:minifiers].include?(type)
			minifier = Minifier.new(&blk)
			@options[:minifiers][type] = minifier
		end

		def clear_cache(type=:all, options={})
			options = {
				:before => nil,
			}.merge(options)
			glob = "#{@options[:root]}#{@options[:cache_dir]}*"
			glob << ".#{type.to_s}" if type && type != :all
			Dir.glob(glob).select{ |f| File.file?(f) }.each do |file|
				# If they've left clear_cache on on a loaded server, we can get races
				# between different threads deleting the same file... Simply ignore the error
				# if we hit it
				begin
					File.delete(file) unless options[:before] && File.mtime(file) > options[:before]
				rescue Errno::EACCES
				end
			end
		end

		def image(path, alt='', attr={})
			@options.resolve_procs!
			# Allow them not to specify an alt text, but provide attr
			attr, alt = alt, '' unless alt.is_a?(String)
			attr = {
				:gen_tag => true,
				:request_path => @options[:request_path],
			}.merge(attr)
			gen_tag = attr.delete(:gen_tag)

			path, namespace = path.split('::', 2).reverse
			attr[:namespace] = (namespace || @options[:default_namespace]).to_sym
			img = Image.new(path, alt, attr)
			return gen_tag ? img.tag(@options) : img.src(@options)
		end
		alias_method :img, :image
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
