module Casset
	class Minifier
		@minify_block

		def initialize(&block)
			@minify_block = block
		end

		def minify(input)
			@minify_block.call(input)
		end
	end
end