class Hash
	# hash2 overrides corresponding key in self, recursively.
	# If opts[:overwtite] == false, will only overwrite if value in self is nil
	def config_merge!(hash2, opts={})
		opts[:overwrite] ||= false
		opts[:no_new] ||= false
		# Add any keys present in self but not hash2 to hash2
		hash2 = self.merge(hash2)
		hash2.each_key do |k|
			if self[k].is_a?(Hash) && hash2[k].is_a?(Hash)
				self[k].config_merge!(hash2[k], opts)
			elsif (self.include?(k) || !opts[:no_new]) && self[k] == nil || opts[:overwrite]
				self[k] = hash2[k]
			end
		end
		return self
	end

	def config_merge(hash2, opts={})
		target = self.config_clone
		target.config_merge!(hash2, opts)
		return target
	end

	def config_clone
		target = {}
		self.each_key do |k|
			if self[k].respond_to?(:config_clone)
				target[k] = self[k].config_clone
			else
				# Can't test for dup, as e.g. Fixnum responds true, but throws exception
				target[k] = self[k].dup rescue self[k]
			end
		end
		return target
	end
end