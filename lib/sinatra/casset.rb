require 'casset'
require 'sinatra/capture'

module Sinatra
	module Casset
		include Capture

		module ConfigMethods
			def self.included(base)
				base.extend ClassMethods
			end
			module ClassMethods
				def parameter(*names)
					names.each do |name|
						define_method name do |*values, &blk|
							@funcs[name] = [] unless @funcs.include?(name)
							@funcs[name] << {:args => [*values], :block => blk}
						end
					end
				end
			end
		end

		class CassetConfig
			include ConfigMethods

			attr_reader :funcs, :configuration

			parameter :add_assets, :add_group, :group_options, :add_namespace,
					:set_default_namespace, :js, :js_content, :css, :css_content,
					:add_content_assets, :enable, :disable, :set_parser,
					:set_minifier, :clear_cache

			def initialize(&blk)
				@funcs, @configuration = {}, {}
				parse_funcs(&blk) if block_given?
			end

			def parse_funcs(&blk)
				blk.arity <= 0 ? instance_eval(&blk) : yield(self) if block_given?
				@funcs
			end

			def config(config)
				@configuration.merge!(config)
			end

		end

		module CassetConfigurator
			extend self

			def create(config_obj)
				casset = ::Casset::Casset.new
				config(casset, :funcs => config_obj.funcs, :config => config_obj.configuration)
			end

			def config(casset, opts)
				casset.config(opts[:config])
				opts[:funcs].each do |key, values|
					values.each do |value|
						casset.send(key, *value[:args], &value[:block])
					end
				end
				casset
			end
		end

		module Helpers
			def assets(&blk)
				if block_given?
					funcs = CassetConfig.new(&blk).funcs
					CassetConfigurator.config(settings.casset, :funcs => funcs)
				end
				settings.casset
			end
		end

		def assets(&blk)
			config = settings.casset_options
			config.parse_funcs(&blk)
			set :casset_options, config
			config
		end

		def self.registered(app)
			app.helpers Helpers
			app.before do
				app.set :casset, CassetConfigurator.create(app.settings.casset_options)
				unless settings.casset_options.configuration.include?(:request_path)
					settings.casset.config({:request_path => request.path_info})
				end
			end
			app.set :casset_options, CassetConfig.new
		end
	end
	register Casset
end