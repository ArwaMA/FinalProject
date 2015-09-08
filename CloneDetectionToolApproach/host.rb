#! /usr/bin/env ruby

## Each commit in the host application is of type Host. 
## It contains same as Commit class, 
## similarity of clones in the host.
## list of files that have added/changed in the host commit and have clone codes with the donor commit that this host is part of, 
## disyance measures, and total number of clones lines.


class Host < Commit

	def initialize(cid, pname, date, number)
		super(cid, pname, date, number)
		@similarity = 0
		@total_distance = 0
		@nline = 0
		@files = Array.new
	end

	def addfile(files)
		@files = files
	end

	def add_total_distance(dis)
		@total_distance = dis
	end

	def addSimilariy(sim)
		@similarity = sim
	end

	def addNline(nline)
		@nline = nline
	end

	def cid
		@cid
	end

	def pname
		@pname
	end

	def files
		@files
	end

	def total_distance
		@total_distance
	end

	def similarity
		@similarity
	end	

	def nline
		@nline
	end	
end
