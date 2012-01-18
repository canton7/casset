module Casset
	module UriRewriter
		PATTERN = /(url|@import)\s*\(\s*(['"]?)([^\/'"][^)\2]+)\2\s*\)/

		def self.rewrite_css(css, before_dir, after_dir)
			# Make sure dirs end in /
			# Can't use << as mutates the string we were passed
			before_dir += '/' unless before_dir.end_with?('/')
			after_dir += '/' unless after_dir.end_with?('/')
			# Move back out of the dir that the file ends up in
			# then back into the dir the file was in before
			rel = "../" * after_dir.count('/') << before_dir

			css.gsub!(PATTERN) do |m|
				type, quote, url = $1, $2, $3
				next m if url.start_with?('data:') || url.include?('://')
				rel_url = self.tidy_url("#{rel}#{url}")
				"#{type}(#{quote}#{rel_url}#{quote})"
			end
			return css
		end

		def self.rewrite_url(request_path, url)
			# URL and requst_path are relative to the same point
			rel = "../" * request_path.count('/') << url
			self.tidy_url(rel)
		end

		def self.tidy_url(url)
			# Get rid of /./ and something/../
			url.gsub!(%r{(/|^)\./}, '\1')
			while url.gsub!(%r{(/|^)[^/\.]+/\.\./}, '\1')
				# yeah...
			end
			return url
		end
	end
end
