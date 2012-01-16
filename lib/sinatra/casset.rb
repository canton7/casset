require 'casset'

module Sinatra
	module Casset
		module CassetConfig
			extend self

			def parse(&blk)
				@options = {}
				parameter :add_assets, :add_group, :group_options, :add_namespace,
					:set_default_namespace, :js, :css, :enable, :disable, :add_parser,
					:set_minifier, :clear_cache
				blk.arity <= 0 ? instance_eval(&blk) : yield(self) if block_given?
				@options
			end

			def parameter(*names)
				names.each do |name|
					define_method name do |*values, &blk|
						#puts "FUNCTION CALLED #{name}"
						@options[name] = {:args => [*values], :block => blk}
						#pp @options
					end
					# TODO this doesn't work
					#define_method "#{name}=" do |*values|
					#	puts "FUNCTION SETTER #{name}"
					#	@options[name] = values
					#end
					#alias_method :"#{name}=", name
				end
			end
		end

		module CassetConfigurator
			extend self

			def create(config)
				casset = ::Casset::Casset.new
				config(config, casset)
			end

			def config(config, casset)
				options = {}
				config.each do |key, value|
					if casset.respond_to?(key)
						casset.send(key, *value[:args], &value[:block])
					else
						options[key] = value[:args].first
					end
				end
				casset.config(options) unless options.empty?
				casset
			end
		end

		module Helpers
			def assets(&blk)
				if block_given?
					config = CassetConfig.parse(&blk)
					CassetConfigurator.config(config, settings.casset)
				end
				settings.casset
			end
		end

		def assets(&blk)
			set :casset_options, CassetConfig.parse(&blk)
		end

		def self.registered(app)
			app.helpers Helpers
			app.before do
				app.set :casset, CassetConfigurator.create(app.settings.casset_options)
			end
		end
	end
	register Casset
end