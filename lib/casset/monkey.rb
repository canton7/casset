class Hash
	# hash2 overrides corresponding key in self, recursively.
	# If opts[:overwtite] == false, will only overwrite if value in self is nil
	def config_merge!(hash2, opts={})
		opts[:overwrite] ||= false
		# Add any keys present in self but not hash2 to hash2
		hash2 = self.merge(hash2)
		hash2.each_key do |k|
			if self[k].is_a?(Hash) && hash2[k].is_a?(Hash)
				self[k].config_merge!(hash2[k], opts)
			elsif hash2[k].is_a?(Hash)
				# If hash2[k] is a hash, but hash1[k] isn't
				self[k] = hash2[k]
			elsif self[k] == nil || opts[:overwrite]
				self[k] = hash2[k]
			end
		end
		return self
	end

	def config_merge(hash2, opts={})
		target = dup
		target.config_merge!(hash2, opts)
		return target
	end
end