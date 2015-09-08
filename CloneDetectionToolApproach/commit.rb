#! /usr/bin/env ruby

## This class represents a commit. 
## It is a super class of donor and host classes. 
## Each commit has commit id (cid), program name (pname), the date in which the commit was created (date), and
## folder number (folderNo); this number is generated while executing the main script and 
## it is only generated to ease the access of the commit later. 

class Commit

	def initialize(cid, pname, date, number)
		@cid = cid
		@pname = pname
		@date = date
		@folderNo = number
	end

	def cid
		@cid
	end

	def pname
		@pname
	end

	def date
		@date
	end

	def folderNo
		@folderNo
	end
end
