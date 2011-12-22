module Casset
	class Parser
		attr_reader :extensions
		@parse_block

		def initialize(extensions, &parse)
			# Allow extensions to be a singel extension
			@extensions = [*extensions]
			@parse_block = parse
		end

		def parse(input)
			@parse_block.call(input)
		end
	end
end