#! /usr/bin/env ruby

## It represents the files that have added/changed in host commit and contain clone code of the predefined clone type. 
## Each file has a name (name), list of clones in the file (clones),  
## and list of donor files that have clone codes with the file.

class Files

	def initialize(name, clones)
		@name = name
		@clones = clones
		@donorFiles = Array.new
	end

	def setName(name)
		@name = name
	end

	def setDonorFiles(files)
		@donorFiles = files
	end

	def name
		@name
	end

	def clones
		@clones
	end

	def donorFiles
		@donorFiles
	end
end
